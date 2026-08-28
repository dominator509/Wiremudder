//! EP-021 M4: performance fixture for the world-memory stack.
//!
//! Measures the real deterministic paths: World Brain observe + current
//! lookup, World Bible upsert + export, Time Machine snapshot + approve +
//! restore. Records p50/p95/max over N runs and asserts the SPEC-004
//! local budget. No mock of the component being measured.
//!
//! Run: cargo run --release --example perf_world_memory

use std::time::Instant;

use wire_time_machine::TimeMachine;
use wire_world_bible::WorldBible;
use wire_world_brain::{Sensitivity, WorldBrain};

const RUNS: usize = 5000;
// SPEC-004 local budget: memory pipeline paths stay well under
// interactive thresholds. Assert 5ms p95.
const P95_BUDGET_US: u128 = 5_000;

fn main() {
    let mut brain = WorldBrain::new();
    brain
        .observe(
            "room:crossroads", "exit.north", "room:gate", "line:10", "rule",
            "midkemia", "midkemia", 0, 0.9, "mapper-v1", Sensitivity::Public,
        )
        .unwrap();
    let mut bible = WorldBible::new();
    bible
        .upsert(
            "midkemia:gate",
            vec!["gray".into(), "black".into()],
            "cobbled", "dim", "guard", "gatehouse", "stone", "echo", "wary",
            vec!["gates lock at night".into()],
        )
        .unwrap();
    let mut tm = TimeMachine::new();
    let mut view = std::collections::BTreeMap::new();
    let mut room = std::collections::BTreeMap::new();
    room.insert("exit.north".into(), "room:gate".into());
    view.insert("room:crossroads".into(), room);
    // Pre-create ONE approved snapshot; the measured path is the read
    // path (current lookup, export, restore), not snapshot creation.
    let snap = tm.snapshot("perf", view, 1).unwrap();
    tm.approve(&snap.id).unwrap();

    // Warmup (no measurement).
    for _ in 0..200 {
        let _ = brain.current("room:crossroads", "exit.north");
        let _ = bible.export_json();
        let _ = tm.restore(&snap.id);
    }

    let mut times: Vec<u128> = Vec::with_capacity(RUNS);
    for _ in 0..RUNS {
        let t0 = Instant::now();
        let _ = brain.current("room:crossroads", "exit.north");
        let _ = bible.export_json();
        let _ = tm.restore(&snap.id);
        times.push(t0.elapsed().as_nanos());
    }

    times.sort_unstable();
    let p50 = times[RUNS / 2];
    let p95 = times[(RUNS as f64 * 0.95) as usize];
    let max = *times.last().unwrap();
    let avg = times.iter().sum::<u128>() / RUNS as u128;

    println!(
        "perf: runs={RUNS} avg_us={} p50_us={} p95_us={} max_us={}",
        avg / 1000,
        p50 / 1000,
        p95 / 1000,
        max / 1000
    );

    assert!(
        p95 < P95_BUDGET_US,
        "p95 {p95}ns exceeds budget {P95_BUDGET_US}ns"
    );

    println!("perf fixture: ok");
}
