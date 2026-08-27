//! EP-015 M4 performance fixture: distillation throughput and capsule
//! size. Emits JSON evidence (SPEC-004, WM-SPEC-026-R04).

use std::time::Instant;
use wire_context::Distiller;

fn main() {
    let path = std::env::temp_dir().join(format!("wm-ep015-m4-perf-{}.db", std::process::id()));
    let _ = std::fs::remove_file(&path);

    let lines: Vec<String> = (0..20_000)
        .map(|i| match i % 8 {
            0 => "You are in The Dark Vault.".to_string(),
            1 => "Obvious exits: north, east".to_string(),
            2 => "A goblin is here.".to_string(),
            3 => format!("You hit the goblin for {i} damage."),
            4 => "You see a rusty sword here.".to_string(),
            5 => "<70>hp <40>m> ".to_string(),
            6 => "A clue: the key is under the rug.".to_string(),
            _ => "The wind howls through the trees.".to_string(),
        })
        .collect();

    let mut d = Distiller::new();
    let t0 = Instant::now();
    let mut events = 0usize;
    for line in &lines {
        events += d.feed_line_collapsed(line).len();
    }
    let total_ms = t0.elapsed().as_secs_f64() * 1000.0;
    let per_line_ms = total_ms / lines.len() as f64;
    let cap = d.into_capsule();

    let ev = serde_json::json!({
        "fixture": "context-distill-budget",
        "lines": lines.len(),
        "events": events,
        "total_ms": total_ms,
        "per_line_ms": per_line_ms,
        "capsule_bytes": cap.approx_bytes(),
        "budget_per_line_ms": 0.1,
        "ok": per_line_ms < 0.1,
        "node": "EP-015",
        "milestone": "M4",
    });
    println!("{}", ev);

    let _ = std::fs::remove_file(&path);
    if !ev["ok"].as_bool().unwrap() {
        std::process::exit(1);
    }
}
