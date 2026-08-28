//! EP-019 M4: performance fixture for the guarded-autopilot decision path.
//!
//! Measures the real deterministic path: propose (visible Action
//! Proposal through the gateway) + confirm/send, including the audit
//! write. Records p50/p95/max over N runs and asserts the SPEC-004 local
//! budget. No mock of the component being measured.
//!
//! Run: cargo run --release --example perf_autopilot

use std::time::Instant;

use wire_actions::GateContext;
use wire_autopilot::{
    AutopilotConfig, AutopilotEngine, AutopilotMode,
};
use wire_policy::{CommandDatabase, CommandRule, HumanTempo, RiskTier};

const RUNS: usize = 2000;

fn main() {
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia")
            .with_mode(AutopilotMode::ConfirmEvery)
            .with_rate_limit(1_000_000, 60_000),
        {
            let mut db = CommandDatabase::new("midkemia");
            db.add_rule(CommandRule::new("say", RiskTier::Safe));
            db
        },
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").expect("enable");

    // Warmup.
    for _ in 0..100 {
        let id = e
            .propose("midkemia", "say hello", &GateContext::ready())
            .expect("propose");
        e.confirm_and_send(&id, &GateContext::ready(), |c| Ok(format!("sent:{c}")))
            .expect("confirm");
    }

    let mut times = Vec::with_capacity(RUNS);
    for _ in 0..RUNS {
        let t0 = Instant::now();
        let id = e
            .propose("midkemia", "say hello", &GateContext::ready())
            .expect("propose");
        e.confirm_and_send(&id, &GateContext::ready(), |c| Ok(format!("sent:{c}")))
            .expect("confirm");
        times.push(t0.elapsed().as_nanos() as u64);
    }

    times.sort_unstable();
    let p50 = times[RUNS / 2];
    let p95 = times[(RUNS as f64 * 0.95) as usize];
    let max = *times.last().unwrap();
    let mean = times.iter().sum::<u64>() / RUNS as u64;

    println!("perf: runs={RUNS} mean_ns={mean} p50_ns={p50} p95_ns={p95} max_ns={max}");

    // Budget: SPEC-004-R11 - autopilot decision + send path is a small
    // local operation; budget 1ms p95 (provider round-trips are separate).
    let budget_ns = 1_000_000u64;
    assert!(p95 < budget_ns, "p95 {p95}ns exceeds budget {budget_ns}ns");
    println!("perf fixture: ok");
}
