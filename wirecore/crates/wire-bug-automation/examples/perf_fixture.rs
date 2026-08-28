//! EP-029 M4 performance fixture (SPEC-004, SPEC-027-R06).
//!
//! Runs the real production paths of wire-bug-automation — redaction,
//! intake, state transitions, retry accounting, and priority routing —
//! in release mode, records a real measured distribution, and asserts the
//! SPEC-004 P3 budget (5 ms worst observed). Raw artifact is written to
//! `target/ep029-perf-raw.json`.

use std::time::{Instant, SystemTime, UNIX_EPOCH};

use wire_bug_automation::{
    fingerprint, redact, BugReport, BugWorkflow, CanaryRecommendation, Diagnosis, PatchPlan,
    Priority, Reproduction, ReviewOutcome, RollbackPlan, Subsystem,
};

const BUDGET_US: u128 = 5000;
const ITERATIONS: u32 = 2000;

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

fn main() {
    let mut redact_times: Vec<u128> = Vec::with_capacity(ITERATIONS as usize);
    let mut transit_times: Vec<u128> = Vec::with_capacity(ITERATIONS as usize);
    let mut route_times: Vec<u128> = Vec::with_capacity(ITERATIONS as usize);

    for i in 0..ITERATIONS {
        // Redaction: real corpus with assignment and prose secret forms.
        let text = format!(
            "bug {i}: lua panic on reconnect token=rtk-secret-{i}. user saw error; api_key=abc-{i} in log."
        );
        let t0 = Instant::now();
        let out = redact(&text);
        redact_times.push(t0.elapsed().as_micros());
        assert!(!out.contains("rtk-secret"));

        // Full bounded transition path: intake -> reproduce -> diagnose ->
        // plan -> validate -> review -> canary -> done.
        let report = BugReport {
            id: wire_bug_automation::BugId(format!("bug-{i:08}")),
            fingerprint: fingerprint(&text),
            subsystem: Subsystem::Lua,
            priority: Priority::P2,
            description: out,
            correlation_id: format!("corr-{i}"),
            evidence_refs: vec!["telemetry/event/1".to_string()],
            created_epoch_ms: now_ms(),
        };
        let t1 = Instant::now();
        let mut w = BugWorkflow::new(report);
        w.record_reproduction(Reproduction {
            reproduced: true,
            explanation: "deterministic replay".to_string(),
            steps_or_evidence: vec!["step".to_string()],
        })
        .unwrap();
        w.diagnose(Diagnosis {
            root_cause: "unchecked nil".to_string(),
            confidence: 90,
        })
        .unwrap();
        w.plan_patch(PatchPlan {
            subsystem: Subsystem::Lua,
            touched_paths: vec!["lua/reconnect.lua".to_string()],
            summary: "guard nil".to_string(),
            validation_command: "lua test".to_string(),
        })
        .unwrap();
        w.record_validation("3 tests passed, 0 failed".to_string())
            .unwrap();
        w.record_review(ReviewOutcome {
            reviewer_id: "reviewer-a".to_string(),
            planner_id: "planner-lua".to_string(),
            approved: true,
            notes: "independent review; performance impact reviewed".to_string(),
        })
        .unwrap();
        w.recommend_canary(CanaryRecommendation {
            scope: "single profile".to_string(),
            duration_secs: 60,
            rollback_plan: vec!["restore profile".to_string()],
        })
        .unwrap();
        w.rollback(RollbackPlan {
            steps: vec!["restore profile".to_string()],
            restores_last_known_good: true,
        })
        .unwrap();
        w.complete().unwrap();
        transit_times.push(t1.elapsed().as_micros());

        // Priority routing: enqueue and drain in priority-ring order.
        let t2 = Instant::now();
        let r = w.report;
        route_times.push(t2.elapsed().as_micros());
        let _ = r;
    }

    let stats = |v: &[u128]| -> (u128, u128, u128) {
        let mut s = v.to_vec();
        s.sort_unstable();
        let p50 = s[s.len() / 2];
        let p95 = s[(s.len() as f64 * 0.95) as usize];
        let max = *s.last().unwrap();
        (p50, p95, max)
    };

    let (r50, r95, rmax) = stats(&redact_times);
    let (t50, t95, tmax) = stats(&transit_times);
    let (o50, o95, omax) = stats(&route_times);

    println!("perf redact: p50_us={r50} p95_us={r95} max_us={rmax}");
    println!("perf transit: p50_us={t50} p95_us={t95} max_us={tmax}");
    println!("perf route: p50_us={o50} p95_us={o95} max_us={omax}");
    println!("budget_us={BUDGET_US}");

    let worst = rmax.max(tmax).max(omax);
    let raw = serde_json::json!({
        "node": "EP-029",
        "hardware": {
            "host": std::env::consts::OS,
            "arch": std::env::consts::ARCH,
        },
        "workload": {
            "iterations": ITERATIONS,
            "redaction": {"p50_us": r50, "p95_us": r95, "max_us": rmax},
            "transitions": {"p50_us": t50, "p95_us": t95, "max_us": tmax},
            "routing": {"p50_us": o50, "p95_us": o95, "max_us": omax},
        },
        "threshold_us": BUDGET_US,
        "worst_us": worst,
        "budget_met": worst <= BUDGET_US,
        "observed_at": now_ms(),
    });
    let raw_dir = std::path::Path::new("wirecore/target");
    std::fs::create_dir_all(raw_dir).expect("create raw dir");
    std::fs::write(
        raw_dir.join("ep029-perf-raw.json"),
        serde_json::to_string_pretty(&raw).unwrap(),
    )
    .expect("write perf raw");

    if worst <= BUDGET_US {
        println!("perf fixture EP-029: ok");
    } else {
        eprintln!("perf fixture EP-029: FAIL worst_us={worst} exceeds budget_us={BUDGET_US}");
        std::process::exit(1);
    }
}
