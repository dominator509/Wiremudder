//! WireMudder EP-014 M4 storage performance fixture.
//! Measures append throughput and FTS query latency on a bounded
//! workload; emits JSON evidence (SPEC-004, WM-SPEC-026-R04).

use std::time::Instant;
use wire_storage::Storage;

fn main() {
    let path = std::env::temp_dir().join(format!("wm-ep014-m4-perf-{}.db", std::process::id()));
    let _ = std::fs::remove_file(&path);
    let mut store = Storage::open(&path).unwrap();
    store.init_schema().unwrap();

    // Append 10,000 lines.
    let t0 = Instant::now();
    for i in 0..10_000 {
        store
            .append_transcript("dom", "in", &format!("line {i} with a griffin word"), 1000 + i)
            .unwrap();
    }
    let append_ms = t0.elapsed().as_secs_f64() * 1000.0;

    // FTS queries (10 queries).
    let t1 = Instant::now();
    for i in 0..10 {
        let _ = store.search(&format!("griffin AND line{i}"), 10).unwrap();
    }
    let search_ms = t1.elapsed().as_secs_f64() * 1000.0;

    let ev = serde_json::json!({
        "fixture": "storage-append-search",
        "lines": 10_000,
        "queries": 10,
        "append_ms": append_ms,
        "search_ms": search_ms,
        "append_per_line_ms": append_ms / 10_000.0,
        "search_per_query_ms": search_ms / 10.0,
        "budget_append_per_line_ms": 0.1,
        "budget_search_per_query_ms": 10.0,
        "ok": append_ms / 10_000.0 < 0.1 && search_ms / 10.0 < 10.0,
        "node": "EP-014",
        "milestone": "M4",
    });
    println!("{}", ev);

    let _ = std::fs::remove_file(&path);
    let _ = std::fs::remove_file(path.with_extension("db-wal"));
    let _ = std::fs::remove_file(path.with_extension("db-shm"));

    if !ev["ok"].as_bool().unwrap() {
        std::process::exit(1);
    }
}
