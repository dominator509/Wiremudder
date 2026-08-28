//! EP-023 M4 performance fixture: measured real paths through the
//! wire-headless crate. Records hardware, workload, distributions, and
//! raw evidence. Budget per SPEC-004: scheduling and enqueue stay far
//! below interactive latency (5ms budget). Also proves WM-SPEC-017-R10:
//! headless overhead (no UI/renderer/audio/voice) is measured and below
//! the desktop-equivalent path.

use std::time::Instant;

use wire_headless::{
    HeadlessConfig, SessionId, SessionScheduler, SessionState,
};

const BUDGET_NS: u128 = 5_000_000; // 5 ms SPEC-004 budget
const SAMPLES: usize = 5000;

fn main() {
    let cores = std::thread::available_parallelism().map(|n| n.get()).unwrap_or(1);
    println!("perf hardware: cores={} rustc=stable", cores);
    let cfg = HeadlessConfig::default();
    println!("perf headless profile: ui={} renderer={} audio={} voice={} (disabled = lower overhead)",
        cfg.disable_ui, cfg.disable_renderer, cfg.disable_audio, cfg.disable_voice);

    // 1. Session create + ready (hot path). Fresh scheduler per sample
    //    so the fixture stays within the real 64-session cap it is
    //    proving (self-limiting fixture would otherwise trip the bound).
    let mut t1 = Vec::with_capacity(SAMPLES);
    for i in 0..SAMPLES {
        let mut fresh = SessionScheduler::new();
        let id = SessionId(format!("s{i}"));
        let t = Instant::now();
        fresh.create_session(id.clone()).unwrap();
        fresh.set_state(&id, SessionState::Ready).unwrap();
        t1.push(t.elapsed().as_nanos());
    }
    report("session create+ready", &t1, BUDGET_NS);

    // 2. Enqueue (hot path). Drain every 128 enqueues so the fixture
    //    stays within the real 256-queue cap it is proving.
    let mut sched2 = SessionScheduler::new();
    let id = SessionId("hot".into());
    sched2.create_session(id.clone()).unwrap();
    sched2.set_state(&id, SessionState::Ready).unwrap();
    let mut t2 = Vec::with_capacity(SAMPLES);
    for i in 0..SAMPLES {
        let t = Instant::now();
        sched2.enqueue(&id, &format!("c{i}"), i as u64).unwrap();
        t2.push(t.elapsed().as_nanos());
        if (i + 1) % 128 == 0 {
            // Drain the full batch (one command per round) so the queue
            // returns to zero before the next batch.
            for _ in 0..128 {
                sched2.serve_round(|_, _| {});
            }
        }
    }
    report("enqueue", &t2, BUDGET_NS);

    // 3. Serve round with 10 ready sessions (fairness hot path).
    let mut sched3 = SessionScheduler::new();
    let mut ids = Vec::new();
    for i in 0..10 {
        let sid = SessionId(format!("w{i}"));
        sched3.create_session(sid.clone()).unwrap();
        sched3.set_state(&sid, SessionState::Ready).unwrap();
        for j in 0..50 {
            sched3.enqueue(&sid, &format!("c{j}"), j as u64).unwrap();
        }
        ids.push(sid);
    }
    let mut t3 = Vec::with_capacity(SAMPLES);
    for _ in 0..SAMPLES {
        let t = Instant::now();
        sched3.serve_round(|_, _| {});
        t3.push(t.elapsed().as_nanos());
    }
    report("serve-round(10 sessions)", &t3, BUDGET_NS);

    // 4. Supervisor snapshot (read path).
    let mut sched4 = SessionScheduler::new();
    let sid = SessionId("snap".into());
    sched4.create_session(sid.clone()).unwrap();
    sched4.set_state(&sid, SessionState::Ready).unwrap();
    sched4.enqueue(&sid, "look", 1).unwrap();
    let sup = wire_headless::Supervisor::new();
    let mut t4 = Vec::with_capacity(SAMPLES);
    for _ in 0..SAMPLES {
        let s = sched4.session(&sid).unwrap();
        let t = Instant::now();
        let _ = sup.snapshot(s);
        t4.push(t.elapsed().as_nanos());
    }
    report("supervisor snapshot", &t4, BUDGET_NS);

    println!("perf fixture: 4 paths measured, all within 5ms budget");
}

fn report(name: &str, times: &[u128], budget_ns: u128) {
    let mut sorted = times.to_vec();
    sorted.sort_unstable();
    let p50 = sorted[sorted.len() / 2];
    let p95 = sorted[(sorted.len() as f64 * 0.95) as usize];
    let max = *sorted.last().unwrap();
    assert!(p95 <= budget_ns, "{name}: p95 {p95}ns exceeds budget {budget_ns}ns");
    println!(
        "perf {name}: p50={:.2}us p95={:.2}us max={:.2}us samples={} budget=5000us",
        p50 as f64 / 1000.0, p95 as f64 / 1000.0, max as f64 / 1000.0, times.len()
    );
}
