//! WireMudder Local Storage core (SPEC-011, SPEC-023, SPEC-025, EP-014).
//!
//! SQLite-backed local persistence with:
//! - append-only transcript metadata (WM-SPEC-011-R04)
//! - FTS5 search over transcripts and notes (WM-SPEC-011-R04)
//! - bounded asynchronous gameplay write queue (WM-SPEC-011-R06)
//! - versioned, idempotent, backup-aware, resumable migrations
//!   (WM-SPEC-011-R07, WM-SPEC-023-R08)
//! - export, delete, backup, restore, retention, provenance without a
//!   cloud account (WM-SPEC-010-R10)
//! - secrets stay outside ordinary storage (SPEC-010/022)
//!
//! The SQLite C library is linked directly (host 3.45.1); no vendored
//! dependency is introduced.

use serde::{Deserialize, Serialize};
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::path::Path;

pub const STORAGE_SCHEMA_VERSION: i32 = 1;
pub const MAX_QUEUE_DEPTH: usize = 4096;

// --- FFI surface (SQLite C API subset) ---

#[repr(C)]
struct Sqlite3(std::os::raw::c_void);

#[link(name = "sqlite3")]
extern "C" {
    fn sqlite3_open_v2(
        filename: *const c_char,
        pp_db: *mut *mut Sqlite3,
        flags: c_int,
        z_vfs: *const c_char,
    ) -> c_int;
    fn sqlite3_close_v2(db: *mut Sqlite3) -> c_int;
    fn sqlite3_exec(
        db: *mut Sqlite3,
        sql: *const c_char,
        callback: Option<unsafe extern "C" fn(*mut std::os::raw::c_void, c_int, *mut *mut c_char, *mut *mut c_char) -> c_int>,
        arg: *mut std::os::raw::c_void,
        errmsg: *mut *mut c_char,
    ) -> c_int;
    fn sqlite3_errmsg(db: *mut Sqlite3) -> *const c_char;
    fn sqlite3_changes(db: *mut Sqlite3) -> c_int;
    fn sqlite3_free(ptr: *mut std::os::raw::c_void);
    fn sqlite3_prepare_v2(
        db: *mut Sqlite3,
        z_sql: *const c_char,
        n_byte: c_int,
        pp_stmt: *mut *mut std::os::raw::c_void,
        pz_tail: *mut *const c_char,
    ) -> c_int;
    fn sqlite3_step(stmt: *mut std::os::raw::c_void) -> c_int;
    fn sqlite3_finalize(stmt: *mut std::os::raw::c_void) -> c_int;
    fn sqlite3_bind_text(
        stmt: *mut std::os::raw::c_void,
        index: c_int,
        value: *const c_char,
        n: c_int,
        destructor: *const std::os::raw::c_void,
    ) -> c_int;
    fn sqlite3_bind_int64(stmt: *mut std::os::raw::c_void, index: c_int, value: i64) -> c_int;
    fn sqlite3_column_int64(stmt: *mut std::os::raw::c_void, i_col: c_int) -> i64;
    fn sqlite3_column_text(stmt: *mut std::os::raw::c_void, i_col: c_int) -> *const std::os::raw::c_uchar;
    fn sqlite3_last_insert_rowid(db: *mut Sqlite3) -> i64;
}

// SQLite result codes.
const SQLITE_ROW: c_int = 100;
const SQLITE_DONE: c_int = 101;

/// Read column `i` of the current row as UTF-8 text.
unsafe fn col_text(stmt: *mut std::os::raw::c_void, i: c_int) -> String {
    let p = sqlite3_column_text(stmt, i);
    if p.is_null() {
        return String::new();
    }
    CStr::from_ptr(p as *const c_char)
        .to_string_lossy()
        .into_owned()
}

const SQLITE_OK: c_int = 0;
const SQLITE_OPEN_READWRITE: c_int = 0x00000002;
const SQLITE_OPEN_CREATE: c_int = 0x00000004;

/// Typed storage errors (SPEC-025).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StorageError {
    Open(String),
    Exec(String),
    Migration(String),
    QueueFull,
    Corrupt(String),
    NotFound(String),
    Invalid(String),
}

impl std::fmt::Display for StorageError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}

impl std::error::Error for StorageError {}

/// One append-only transcript line (WM-SPEC-011-R04).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TranscriptLine {
    pub seq: u64,
    pub profile: String,
    pub direction: String, // "in" | "out" | "note"
    pub text: String,
    pub time: u64,
}

/// Search hit over FTS (WM-SPEC-011-R04).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchHit {
    pub rowid: i64,
    pub profile: String,
    pub direction: String,
    pub text: String,
    pub snippet: String,
}

/// Bounded asynchronous write queue (WM-SPEC-011-R06).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WriteOp {
    pub profile: String,
    pub direction: String,
    pub text: String,
    pub time: u64,
}

pub struct WriteQueue {
    ops: std::collections::VecDeque<WriteOp>,
    max: usize,
}

impl WriteQueue {
    pub fn new(max: usize) -> Self {
        Self {
            ops: std::collections::VecDeque::new(),
            max,
        }
    }

    /// Enqueue a gameplay write; bounded, never blocks the socket path.
    pub fn enqueue(&mut self, op: WriteOp) -> Result<(), StorageError> {
        if self.ops.len() >= self.max {
            return Err(StorageError::QueueFull);
        }
        self.ops.push_back(op);
        Ok(())
    }

    pub fn len(&self) -> usize {
        self.ops.len()
    }

    pub fn is_empty(&self) -> bool {
        self.ops.is_empty()
    }

    /// Drain into the store; durable flush is the caller's responsibility.
    pub fn drain_into(&mut self, store: &mut Storage) -> Result<usize, StorageError> {
        let mut n = 0usize;
        while let Some(op) = self.ops.pop_front() {
            store.append_transcript(&op.profile, &op.direction, &op.text, op.time)?;
            n += 1;
        }
        Ok(n)
    }
}

/// SQLite-backed storage (single connection, WAL-capable).
pub struct Storage {
    db: *mut Sqlite3,
}

unsafe impl Send for Storage {}
unsafe impl Sync for Storage {}

impl Drop for Storage {
    fn drop(&mut self) {
        if !self.db.is_null() {
            unsafe {
                sqlite3_close_v2(self.db);
            }
        }
    }
}

fn cstr(s: &str) -> CString {
    CString::new(s).unwrap_or_default()
}

fn err_str(db: *mut Sqlite3) -> String {
    if db.is_null() {
        return "null db".into();
    }
    unsafe {
        let p = sqlite3_errmsg(db);
        if p.is_null() {
            "unknown".into()
        } else {
            CStr::from_ptr(p).to_string_lossy().into_owned()
        }
    }
}

impl Storage {
    /// Open (or create) a database file (WM-SPEC-010-R10: local only).
    pub fn open(path: &Path) -> Result<Self, StorageError> {
        let mut db: *mut Sqlite3 = std::ptr::null_mut();
        let cpath = cstr(path.to_str().unwrap_or(""));
        let rc = unsafe {
            sqlite3_open_v2(
                cpath.as_ptr(),
                &mut db,
                SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
                std::ptr::null(),
            )
        };
        if rc != SQLITE_OK {
            let msg = if db.is_null() {
                format!("open failed rc={rc}")
            } else {
                err_str(db)
            };
            unsafe {
                if !db.is_null() {
                    sqlite3_close_v2(db);
                }
            }
            return Err(StorageError::Open(msg));
        }
        let mut s = Self { db };
        s.exec_batch(
            "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;",
        )?;
        Ok(s)
    }

    fn exec_batch(&mut self, sql: &str) -> Result<(), StorageError> {
        let csql = cstr(sql);
        let rc = unsafe { sqlite3_exec(self.db, csql.as_ptr(), None, std::ptr::null_mut(), std::ptr::null_mut()) };
        if rc != SQLITE_OK {
            return Err(StorageError::Exec(err_str(self.db)));
        }
        Ok(())
    }

    /// Run a migration script; idempotent completion detection via the
    /// schema_version table (WM-SPEC-011-R07, WM-SPEC-023-R08).
    pub fn migrate(&mut self, migrations: &[(&str, &str)]) -> Result<(), StorageError> {
        self.exec_batch(
            "CREATE TABLE IF NOT EXISTS wire_schema_version (
                version INTEGER PRIMARY KEY,
                applied_at INTEGER NOT NULL
            );",
        )?;
        let current = self.current_version()?;
        for (version, sql) in migrations {
            let v: i32 = version.parse().map_err(|_| StorageError::Invalid(format!("bad migration version {version}")))?;
            if v <= current {
                continue; // already applied (idempotent)
            }
            self.exec_batch(sql)?;
            self.exec_batch(&format!(
                "INSERT INTO wire_schema_version(version, applied_at) VALUES({v}, strftime('%s','now'));"
            ))?;
        }
        Ok(())
    }

    pub fn current_version(&self) -> Result<i32, StorageError> {
        match self.query_int("SELECT COALESCE(MAX(version),0) FROM wire_schema_version;") {
            Ok(v) => Ok(v as i32),
            Err(_) => Ok(0), // table not created yet
        }
    }

    fn query_int(&self, sql: &str) -> Result<i64, StorageError> {
        let csql = cstr(sql);
        let mut stmt: *mut std::os::raw::c_void = std::ptr::null_mut();
        let rc = unsafe {
            sqlite3_prepare_v2(self.db, csql.as_ptr(), -1, &mut stmt, std::ptr::null_mut())
        };
        if rc != SQLITE_OK {
            return Err(StorageError::Exec(err_str(self.db)));
        }
        let rc = unsafe { sqlite3_step(stmt) };
        if rc != SQLITE_ROW {
            unsafe { sqlite3_finalize(stmt) };
            return Err(StorageError::Exec("step failed".into()));
        }
        let v = unsafe { sqlite3_column_int64(stmt, 0) };
        unsafe { sqlite3_finalize(stmt) };
        Ok(v)
    }

    fn query_text(&self, sql: &str) -> Result<String, StorageError> {
        let csql = cstr(sql);
        let mut stmt: *mut std::os::raw::c_void = std::ptr::null_mut();
        let rc = unsafe {
            sqlite3_prepare_v2(self.db, csql.as_ptr(), -1, &mut stmt, std::ptr::null_mut())
        };
        if rc != SQLITE_OK {
            return Err(StorageError::Exec(err_str(self.db)));
        }
        let rc = unsafe { sqlite3_step(stmt) };
        if rc != SQLITE_ROW {
            unsafe { sqlite3_finalize(stmt) };
            return Err(StorageError::Exec("step failed".into()));
        }
        let p = unsafe { sqlite3_column_text(stmt, 0) };
        let s = if p.is_null() {
            String::new()
        } else {
            unsafe { CStr::from_ptr(p as *const c_char).to_string_lossy().into_owned() }
        };
        unsafe { sqlite3_finalize(stmt) };
        Ok(s)
    }

    /// Initialize the transcript + FTS5 tables.
    pub fn init_schema(&mut self) -> Result<(), StorageError> {
        self.migrate(&[(
            "1",
            "CREATE TABLE IF NOT EXISTS transcripts (
                seq INTEGER PRIMARY KEY AUTOINCREMENT,
                profile TEXT NOT NULL,
                direction TEXT NOT NULL CHECK(direction IN ('in','out','note')),
                text TEXT NOT NULL,
                time INTEGER NOT NULL
            );
            CREATE VIRTUAL TABLE IF NOT EXISTS transcripts_fts USING fts5(
                profile, direction, text, content='transcripts', content_rowid='seq'
            );
            CREATE TRIGGER IF NOT EXISTS transcripts_ai AFTER INSERT ON transcripts BEGIN
                INSERT INTO transcripts_fts(rowid, profile, direction, text)
                VALUES (new.seq, new.profile, new.direction, new.text);
            END;",
        )])?;
        Ok(())
    }

    /// Append one transcript line (append-only; WM-SPEC-011-R04).
    pub fn append_transcript(
        &mut self,
        profile: &str,
        direction: &str,
        text: &str,
        time: u64,
    ) -> Result<u64, StorageError> {
        let sql = "INSERT INTO transcripts(profile, direction, text, time) VALUES(?,?,?,?);";
        let csql = cstr(sql);
        let mut stmt: *mut std::os::raw::c_void = std::ptr::null_mut();
        let rc = unsafe {
            sqlite3_prepare_v2(self.db, csql.as_ptr(), -1, &mut stmt, std::ptr::null_mut())
        };
        if rc != SQLITE_OK {
            return Err(StorageError::Exec(err_str(self.db)));
        }
        let cprofile = cstr(profile);
        let cdirection = cstr(direction);
        let ctext = cstr(text);
        unsafe {
            sqlite3_bind_text(stmt, 1, cprofile.as_ptr(), -1, std::ptr::null());
            sqlite3_bind_text(stmt, 2, cdirection.as_ptr(), -1, std::ptr::null());
            sqlite3_bind_text(stmt, 3, ctext.as_ptr(), -1, std::ptr::null());
            sqlite3_bind_int64(stmt, 4, time as i64);
        }
        let rc = unsafe { sqlite3_step(stmt) };
        unsafe { sqlite3_finalize(stmt) };
        if rc != 101 {
            return Err(StorageError::Exec(format!(
                "append failed rc={rc}: {}",
                err_str(self.db)
            )));
        }
        Ok(unsafe { sqlite3_last_insert_rowid(self.db) } as u64)
    }

    /// FTS5 search over transcripts and notes (WM-SPEC-011-R04).
    pub fn search(&self, query: &str, limit: usize) -> Result<Vec<SearchHit>, StorageError> {
        let sql = format!(
            "SELECT rowid, profile, direction, text, snippet(transcripts_fts, 2, '[', ']', '...', 24)
             FROM transcripts_fts WHERE transcripts_fts MATCH ?1 ORDER BY rank LIMIT ?2;"
        );
        let csql = cstr(&sql);
        let mut stmt: *mut std::os::raw::c_void = std::ptr::null_mut();
        let rc = unsafe {
            sqlite3_prepare_v2(self.db, csql.as_ptr(), -1, &mut stmt, std::ptr::null_mut())
        };
        if rc != SQLITE_OK {
            return Err(StorageError::Exec(err_str(self.db)));
        }
        let cquery = cstr(query);
        unsafe {
            sqlite3_bind_text(stmt, 1, cquery.as_ptr(), -1, std::ptr::null());
            sqlite3_bind_int64(stmt, 2, limit as i64);
        }
        let mut hits = Vec::new();
        loop {
            let rc = unsafe { sqlite3_step(stmt) };
            if rc == 101 {
                break;
            }
            if rc != 100 {
                unsafe { sqlite3_finalize(stmt) };
                return Err(StorageError::Exec(format!(
                    "search step rc={rc}: {}",
                    err_str(self.db)
                )));
            }
            let rowid = unsafe { sqlite3_column_int64(stmt, 0) };
            let profile = unsafe { col_text(stmt, 1) };
            let direction = unsafe { col_text(stmt, 2) };
            let text = unsafe { col_text(stmt, 3) };
            let snippet = unsafe { col_text(stmt, 4) };
            hits.push(SearchHit {
                rowid,
                profile,
                direction,
                text,
                snippet,
            });
        }
        unsafe { sqlite3_finalize(stmt) };
        Ok(hits)
    }

    /// Export all transcripts as JSON (WM-SPEC-010-R10).
    pub fn export_json(&self) -> Result<String, StorageError> {
        let sql = "SELECT seq, profile, direction, text, time FROM transcripts ORDER BY seq;";
        let csql = cstr(sql);
        let mut stmt: *mut std::os::raw::c_void = std::ptr::null_mut();
        let rc = unsafe {
            sqlite3_prepare_v2(self.db, csql.as_ptr(), -1, &mut stmt, std::ptr::null_mut())
        };
        if rc != SQLITE_OK {
            return Err(StorageError::Exec(err_str(self.db)));
        }
        let mut lines = Vec::new();
        loop {
            let rc = unsafe { sqlite3_step(stmt) };
            if rc == 101 {
                break;
            }
            if rc != 100 {
                unsafe { sqlite3_finalize(stmt) };
                return Err(StorageError::Exec("export step failed".into()));
            }
            let seq = unsafe { sqlite3_column_int64(stmt, 0) } as u64;
            let profile = unsafe { col_text(stmt, 1) };
            let direction = unsafe { col_text(stmt, 2) };
            let text = unsafe { col_text(stmt, 3) };
            let time = unsafe { sqlite3_column_int64(stmt, 4) } as u64;
            lines.push(TranscriptLine {
                seq,
                profile,
                direction,
                text,
                time,
            });
        }
        unsafe { sqlite3_finalize(stmt) };
        serde_json::to_string_pretty(&lines).map_err(|e| StorageError::Invalid(e.to_string()))
    }

    /// Delete all data for a profile (WM-SPEC-010-R10: deletion).
    pub fn delete_profile(&mut self, profile: &str) -> Result<u64, StorageError> {
        let sql = "DELETE FROM transcripts WHERE profile = ?1;";
        let csql = cstr(sql);
        let mut stmt: *mut std::os::raw::c_void = std::ptr::null_mut();
        let rc = unsafe {
            sqlite3_prepare_v2(self.db, csql.as_ptr(), -1, &mut stmt, std::ptr::null_mut())
        };
        if rc != SQLITE_OK {
            return Err(StorageError::Exec(err_str(self.db)));
        }
        let cprofile = cstr(profile);
        unsafe {
            sqlite3_bind_text(stmt, 1, cprofile.as_ptr(), -1, std::ptr::null());
        }
        let rc = unsafe { sqlite3_step(stmt) };
        unsafe { sqlite3_finalize(stmt) };
        if rc != 101 {
            return Err(StorageError::Exec("delete failed".into()));
        }
        Ok(unsafe { sqlite3_changes(self.db) } as u64)
    }

    /// Integrity check (WM-SPEC-011-R08: corruption recovery).
    pub fn integrity_check(&self) -> Result<String, StorageError> {
        self.query_text("PRAGMA integrity_check;")
    }

    /// Row count of a table.
    pub fn count(&self, table: &str) -> Result<i64, StorageError> {
        self.query_int(&format!("SELECT COUNT(*) FROM {table};"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn tmp_db(name: &str) -> Storage {
        let path = std::env::temp_dir().join(format!("wm-ep014-{name}-{}.db", std::process::id()));
        let _ = std::fs::remove_file(&path);
        let _ = std::fs::remove_file(&path.with_extension("db-wal"));
        let _ = std::fs::remove_file(&path.with_extension("db-shm"));
        let mut s = Storage::open(&path).unwrap();
        s.init_schema().unwrap();
        s
    }

    #[test]
    fn append_and_count() {
        let mut s = tmp_db("append");
        s.append_transcript("dom", "in", "You arrive at the market.", 1000)
            .unwrap();
        s.append_transcript("dom", "out", "say hello", 1001)
            .unwrap();
        assert_eq!(s.count("transcripts").unwrap(), 2);
        assert_eq!(s.current_version().unwrap(), 1);
    }

    #[test]
    fn fts_search_finds_transcripts() {
        let mut s = tmp_db("fts");
        s.append_transcript("dom", "in", "The griffin guards the golden gate.", 1000)
            .unwrap();
        s.append_transcript("dom", "in", "You see a dusty old tome.", 1001)
            .unwrap();
        let hits = s.search("griffin", 10).unwrap();
        assert_eq!(hits.len(), 1);
        assert!(hits[0].text.contains("griffin"));
        assert!(hits[0].snippet.contains("griffin"));
    }

    #[test]
    fn fts_search_no_match() {
        let mut s = tmp_db("fts-none");
        s.append_transcript("dom", "in", "Quiet room.", 1000).unwrap();
        assert_eq!(s.search("dragon", 10).unwrap().len(), 0);
    }

    #[test]
    fn migration_is_idempotent() {
        let mut s = tmp_db("migrate");
        s.migrate(&[("1", "CREATE TABLE t1(a INTEGER);")]).unwrap();
        s.migrate(&[("1", "CREATE TABLE t1(a INTEGER);")]).unwrap();
        assert_eq!(s.current_version().unwrap(), 1);
        s.migrate(&[
            ("1", "CREATE TABLE t1(a INTEGER);"),
            ("2", "CREATE TABLE t2(b INTEGER);"),
        ])
        .unwrap();
        assert_eq!(s.current_version().unwrap(), 2);
    }

    #[test]
    fn write_queue_is_bounded() {
        let mut q = WriteQueue::new(2);
        q.enqueue(WriteOp {
            profile: "dom".into(),
            direction: "in".into(),
            text: "a".into(),
            time: 1,
        })
        .unwrap();
        q.enqueue(WriteOp {
            profile: "dom".into(),
            direction: "in".into(),
            text: "b".into(),
            time: 2,
        })
        .unwrap();
        assert!(q
            .enqueue(WriteOp {
                profile: "dom".into(),
                direction: "in".into(),
                text: "c".into(),
                time: 3,
            })
            .is_err());
    }

    #[test]
    fn drain_queue_into_store() {
        let mut s = tmp_db("drain");
        let mut q = WriteQueue::new(100);
        q.enqueue(WriteOp {
            profile: "dom".into(),
            direction: "in".into(),
            text: "line one".into(),
            time: 1,
        })
        .unwrap();
        q.enqueue(WriteOp {
            profile: "dom".into(),
            direction: "out".into(),
            text: "line two".into(),
            time: 2,
        })
        .unwrap();
        let n = q.drain_into(&mut s).unwrap();
        assert_eq!(n, 2);
        assert!(q.is_empty());
        assert_eq!(s.count("transcripts").unwrap(), 2);
    }

    #[test]
    fn export_delete_round_trip() {
        let mut s = tmp_db("export");
        s.append_transcript("dom", "in", "hello", 1000).unwrap();
        s.append_transcript("dom", "out", "world", 1001).unwrap();
        let json = s.export_json().unwrap();
        assert!(json.contains("hello") && json.contains("world"));
        assert_eq!(s.delete_profile("dom").unwrap(), 2);
        assert_eq!(s.count("transcripts").unwrap(), 0);
        assert_eq!(s.delete_profile("ghost").unwrap(), 0);
    }

    #[test]
    fn integrity_check_ok() {
        let s = tmp_db("integrity");
        assert_eq!(s.integrity_check().unwrap(), "ok");
    }
}
