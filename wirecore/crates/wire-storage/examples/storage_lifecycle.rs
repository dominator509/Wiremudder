//! WireMudder EP-014 M3 integration oracle (Rust side).
//! Exercises the real wire-storage crate through a complete transcript
//! lifecycle: open -> migrate -> async queue writes -> drain -> search
//! -> export -> delete. Prints deterministic outcomes.

use wire_storage::{Storage, WriteOp, WriteQueue};

fn main() {
    let path = std::env::temp_dir().join(format!("wm-ep014-m3-{}.db", std::process::id()));
    let _ = std::fs::remove_file(&path);
    let _ = std::fs::remove_file(path.with_extension("db-wal"));
    let _ = std::fs::remove_file(path.with_extension("db-shm"));

    let mut store = Storage::open(&path).unwrap();
    store.init_schema().unwrap();

    // Gameplay writes go to the bounded queue first (WM-SPEC-011-R06).
    let mut q = WriteQueue::new(4096);
    q.enqueue(WriteOp {
        profile: "dom".into(),
        direction: "in".into(),
        text: "You arrive at the northern gate.".into(),
        time: 1000,
    })
    .unwrap();
    q.enqueue(WriteOp {
        profile: "dom".into(),
        direction: "out".into(),
        text: "look".into(),
        time: 1001,
    })
    .unwrap();
    q.enqueue(WriteOp {
        profile: "dom".into(),
        direction: "in".into(),
        text: "The griffin watches from the wall.".into(),
        time: 1002,
    })
    .unwrap();
    println!("queue-depth:{}", q.len());

    // Drain into the store (async flush).
    let drained = q.drain_into(&mut store).unwrap();
    println!("drained:{}", drained);
    println!("stored:{}", store.count("transcripts").unwrap());

    // FTS search.
    let hits = store.search("griffin", 10).unwrap();
    println!("search-hits:{}", hits.len());
    println!("search-snippet:{}", hits[0].snippet);

    // Export (WM-SPEC-010-R10).
    let json = store.export_json().unwrap();
    println!("export-has-griffin:{}", json.contains("griffin"));

    // Delete profile.
    let removed = store.delete_profile("dom").unwrap();
    println!("deleted:{}", removed);
    println!("after-delete:{}", store.count("transcripts").unwrap());

    // Integrity.
    println!("integrity:{}", store.integrity_check().unwrap());

    let _ = std::fs::remove_file(&path);
    let _ = std::fs::remove_file(path.with_extension("db-wal"));
    let _ = std::fs::remove_file(path.with_extension("db-shm"));
}
