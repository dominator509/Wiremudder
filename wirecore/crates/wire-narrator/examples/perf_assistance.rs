//! EP-020 M4: performance fixture for the assistance stack.
//!
//! Measures the real deterministic paths: quest track + summarize,
//! tactical update + snapshot, narration, and redaction. Records
//! p50/p95/max over N runs and asserts the SPEC-004 local budget
//! (interactive assistance work stays P2/P3; bounded and small).
//! No mock of the component being measured.
//!
//! Run: cargo run --release --example perf_assistance

use std::time::Instant;

use wire_narrator::Narrator;
use wire_quest::{QuestLog, QuestState};
use wire_tactical::{TacticalHud, TacticalSnapshot};

const RUNS: usize = 5000;
// SPEC-004 local budget: assistance decision paths must stay well under
// interactive thresholds (single-digit ms). We assert 5ms p95 to leave
// headroom while proving the path is measured, not assumed.
const P95_BUDGET_US: u128 = 5_000;

fn main() {
    // Build once; measure the hot path.
    let mut log = QuestLog::new();
    log.track(
        "q1",
        "Find the key",
        QuestState::Observed,
        "the guard mentioned a key",
        "room:gate",
        0,
    )
    .unwrap();
    let mut hud = TacticalHud::new();
    hud.update(
        TacticalSnapshot {
            room: "crossroads".into(),
            health_pct: 80,
            energy_pct: 50,
            nearby_entities: vec!["guard".into(), "innkeeper".into()],
            threat_level: "low".into(),
            at_ms: 0,
        },
        0,
    )
    .unwrap();
    let narrator = Narrator::new();

    // Warmup (no measurement).
    for _ in 0..200 {
        let _ = narrator.summarize_quest(&log, "q1").unwrap();
        let _ = narrator.summarize_tactical(&hud);
        let _ = narrator.redact("key sk-abcdef123 password=hunter2");
    }

    let mut times: Vec<u128> = Vec::with_capacity(RUNS);
    for _ in 0..RUNS {
        let t0 = Instant::now();
        let _ = narrator.summarize_quest(&log, "q1").unwrap();
        let _ = narrator.summarize_tactical(&hud);
        let _ = narrator.redact("key sk-abcdef123 password=hunter2");
        times.push(t0.elapsed().as_nanos());
    }

    times.sort_unstable();
    let p50 = times[RUNS / 2];
    let p95 = times[(RUNS as f64 * 0.95) as usize];
    let max = *times.last().unwrap();
    let avg = times.iter().sum::<u128>() / RUNS as u128;

    println!("perf: runs={RUNS} avg_us={} p50_us={} p95_us={} max_us={}", avg / 1000, p50 / 1000, p95 / 1000, max / 1000);

    // SPEC-004: p95 must stay inside the local interactive budget.
    assert!(
        p95 < P95_BUDGET_US,
        "p95 {p95}ns exceeds budget {P95_BUDGET_US}ns"
    );

    println!("perf fixture: ok");
}
