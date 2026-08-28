//! EP-022 M4 performance fixture: measured real paths through the
//! wire-debugger crate. Records hardware, workload, distributions, and
//! raw evidence. Budget per SPEC-004: automation surfaces must stay far
//! below interactive latency (5ms budget for this node's core paths).

use std::time::Instant;

use wire_debugger::{
    DraftKind, FixtureEvent, MacroForge, ReplayFixture, ScriptDebugger, TriggerLab, AiDebugger,
};

const BUDGET_NS: u128 = 5_000_000; // 5 ms SPEC-004 budget for core paths
const SAMPLES: usize = 2000;

fn main() {
    // Hardware/workload header (raw evidence).
    let cores = std::thread::available_parallelism().map(|n| n.get()).unwrap_or(1);
    println!("perf hardware: cores={} rustc=stable", cores);

    // 1. Macro Forge: create + approve (hot path).
    let mut forge = MacroForge::new();
    let mut times = Vec::with_capacity(SAMPLES);
    for i in 0..SAMPLES {
        let t = Instant::now();
        forge
            .create(&format!("m{i}"), DraftKind::Macro, "heal", "send(\"cure light\")", i as u64)
            .unwrap();
        forge.approve(&format!("m{i}")).unwrap();
        times.push(t.elapsed().as_nanos());
    }
    report("macro-forge create+approve", &times, BUDGET_NS);

    // 2. Trigger Test Lab: deterministic replay of a 50-event fixture.
    let mut lab = TriggerLab::new();
    let fx = ReplayFixture {
        id: "perf".into(),
        name: "perf fixture".into(),
        events: (1..=50)
            .map(|i| FixtureEvent { at_step: i, line: format!("line {i}"), matches: String::new(), expect: None })
            .collect(),
    };
    lab.add_fixture(fx).unwrap();
    let mut times2 = Vec::with_capacity(SAMPLES);
    for _ in 0..SAMPLES {
        let t = Instant::now();
        let run = lab.replay("perf", |_| Some("effect".into()), 1_000_000).unwrap();
        assert!(run.finished);
        times2.push(t.elapsed().as_nanos());
    }
    report("trigger-lab replay(50 events)", &times2, BUDGET_NS);

    // 3. AI Debugger: diagnose with approved evidence (10 lines).
    let mut ai = AiDebugger::new();
    let evidence: Vec<String> = (0..10).map(|i| format!("line {i}")).collect();
    ai.approve_evidence("perf-ev", evidence).unwrap();
    let mut times3 = Vec::with_capacity(SAMPLES);
    for i in 0..SAMPLES {
        let t = Instant::now();
        ai.diagnose(
            &format!("d{i}"),
            "perf-ev",
            "hypothesis",
            "reproduction",
            "patch plan",
            vec!["test".into()],
            "risk",
            "rollback",
        )
        .unwrap();
        times3.push(t.elapsed().as_nanos());
    }
    report("ai-debugger diagnose", &times3, BUDGET_NS);

    // 4. Variable inspection: set + read (hot path). Reuses one variable
    //    so the ring stays within its real bound (self-limiting fixture
    //    would otherwise trip the 512 cap it is proving).
    let mut dbg = ScriptDebugger::new();
    let mut times4 = Vec::with_capacity(SAMPLES);
    for i in 0..SAMPLES {
        let t = Instant::now();
        dbg.set_variable("var", "public", Some(format!("{i}"))).unwrap();
        let _ = dbg.variable("var");
        times4.push(t.elapsed().as_nanos());
    }
    report("variable set+read", &times4, BUDGET_NS);
    println!("perf fixture: 4 paths measured, all within 5ms budget");
}

fn report(name: &str, times: &[u128], budget_ns: u128) {
    let mut sorted = times.to_vec();
    sorted.sort_unstable();
    let p50 = sorted[sorted.len() / 2];
    let p95 = sorted[(sorted.len() as f64 * 0.95) as usize];
    let max = *sorted.last().unwrap();
    let p50_us = p50 as f64 / 1_000.0;
    let p95_us = p95 as f64 / 1_000.0;
    let max_us = max as f64 / 1_000.0;
    assert!(p95 <= budget_ns, "{name}: p95 {p95}ns exceeds budget {budget_ns}ns");
    println!(
        "perf {name}: p50={:.2}us p95={:.2}us max={:.2}us samples={} budget=5000us",
        p50_us, p95_us, max_us, times.len()
    );
}
