//! WireMudder EP-014 M4 security matrix (Rust side).
//! Proves: transcript content stays data (injection-shaped text is not
//! executed), search terms cannot break the FTS query context, and
//! deletion is per-profile scoped (no cross-profile leakage).

use wire_storage::{Storage, StorageError, WriteOp, WriteQueue};

fn main() {
    let path = std::env::temp_dir().join(format!("wm-ep014-m4-sec-{}.db", std::process::id()));
    let _ = std::fs::remove_file(&path);
    let mut store = Storage::open(&path).unwrap();
    store.init_schema().unwrap();

    // 1. Injection-shaped transcript text round-trips as data.
    let mut q = WriteQueue::new(100);
    q.enqueue(WriteOp {
        profile: "dom".into(),
        direction: "in".into(),
        text: "'; DROP TABLE transcripts; --".into(),
        time: 1,
    })
    .unwrap();
    q.drain_into(&mut store).unwrap();
    let json = store.export_json().unwrap();
    println!("injection-data:{}", if json.contains("DROP TABLE") { "ok" } else { "fail" });

    // 2. FTS search with special chars is safe: hostile terms yield a
    // typed error (or results), never a panic, and never break the
    // connection for subsequent legitimate searches.
    let r = store.search("griffin OR '*'", 10);
    let safe = r.is_ok()
        || matches!(
            r,
            Err(StorageError::Exec(_)) | Err(StorageError::Invalid(_))
        );
    println!("search-safe:{}", if safe { "ok" } else { "fail" });

    // 3. Per-profile deletion does not affect other profiles.
    store.append_transcript("alice", "in", "alice secret", 1000).unwrap();
    store.append_transcript("bob", "in", "bob note", 1001).unwrap();
    let removed = store.delete_profile("alice").unwrap();
    let bob_left = store.search("bob", 10).unwrap().len() == 1;
    let alice_hits = store.search("alice", 10).unwrap();
    let alice_gone = alice_hits.is_empty();
    println!("scoped-delete:{}", if removed == 1 && bob_left && alice_gone { "ok" } else { "fail" });

    let _ = std::fs::remove_file(&path);
    let _ = std::fs::remove_file(path.with_extension("db-wal"));
    let _ = std::fs::remove_file(path.with_extension("db-shm"));
}
