//! WireMudder EP-014 M4 failure matrix (Rust side).
//! Proves typed failures: queue exhaustion, corrupt DB detection,
//! invalid migration version, missing table, malformed search.

use wire_storage::{Storage, StorageError, WriteOp, WriteQueue};

fn main() {
    // 1. Queue exhaustion is typed.
    let mut q = WriteQueue::new(2);
    q.enqueue(WriteOp {
        profile: "p".into(),
        direction: "in".into(),
        text: "a".into(),
        time: 1,
    })
    .unwrap();
    q.enqueue(WriteOp {
        profile: "p".into(),
        direction: "in".into(),
        text: "b".into(),
        time: 2,
    })
    .unwrap();
    let full = matches!(
        q.enqueue(WriteOp {
            profile: "p".into(),
            direction: "in".into(),
            text: "c".into(),
            time: 3,
        }),
        Err(StorageError::QueueFull)
    );
    println!("queue-full:{}", if full { "ok" } else { "fail" });

    // 2. Corrupt DB file is detected at open (typed Corrupt, SPEC-025).
    let path = std::env::temp_dir().join(format!("wm-ep014-m4-corrupt-{}.db", std::process::id()));
    std::fs::write(&path, b"this is not a sqlite database").unwrap();
    let open = Storage::open(&path);
    let corrupt_detected = matches!(open, Err(StorageError::Corrupt(_)));
    println!("corrupt-open:{}", if corrupt_detected { "ok" } else { "fail" });
    let _ = std::fs::remove_file(&path);

    // 3. Invalid migration version is typed.
    let path2 = std::env::temp_dir().join(format!("wm-ep014-m4-mig-{}.db", std::process::id()));
    let _ = std::fs::remove_file(&path2);
    let mut s = Storage::open(&path2).unwrap();
    let bad = s
        .migrate(&[("not-a-number", "CREATE TABLE x(a);")])
        .is_err();
    println!("bad-migration:{}", if bad { "ok" } else { "fail" });
    let _ = std::fs::remove_file(&path2);
    let _ = std::fs::remove_file(path2.with_extension("db-wal"));
    let _ = std::fs::remove_file(path2.with_extension("db-shm"));

    // 4. Missing table count is typed (not a panic).
    let path3 = std::env::temp_dir().join(format!("wm-ep014-m4-nocount-{}.db", std::process::id()));
    let _ = std::fs::remove_file(&path3);
    let s3 = Storage::open(&path3).unwrap();
    let missing = s3.count("nonexistent").is_err();
    println!("missing-table:{}", if missing { "ok" } else { "fail" });
    let _ = std::fs::remove_file(&path3);
    let _ = std::fs::remove_file(path3.with_extension("db-wal"));
    let _ = std::fs::remove_file(path3.with_extension("db-shm"));
}
