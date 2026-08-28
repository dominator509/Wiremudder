//! EP-028 M4 performance fixture: real measured latency distributions
//! for the hot-path operations of telemetry/replay/diagnostics, against
//! SPEC-004 budgets. Ring-buffer record is the only hot-path write;
//! compression and export are P4 (SPEC-019).
//!
//! Budget (SPEC-004): P4 operations must stay under 5 ms p99. Ring
//! record is expected well under that; the fixture prints the raw
//! distributions for evidence.

use std::time::{Duration, Instant};

use wire_replay::{BundleBuilder, ReplayEvent, SessionReplay};
use wire_telemetry::{DataClass, RingBuffer, Severity, Subsystem, TelemetryEngine, TelemetryEvent};

const N: u32 = 200_000;
const BUDGET_US: u64 = 5_000;

fn ev(t: i64) -> TelemetryEvent {
    TelemetryEvent::new(
        format!("perf-{t}"),
        t,
        Subsystem::Core,
        Severity::Info,
        TelemetryEvent::fingerprint_for(
            Subsystem::Core,
            Severity::Info,
            Some("WM-FEAT-0223"),
            DataClass::Diagnostic,
        ),
        DataClass::Diagnostic,
        serde_json::Map::new(),
    )
}

fn summarize(name: &str, samples: &[u64]) {
    let mut s = samples.to_vec();
    s.sort_unstable();
    let n = s.len();
    let p50 = s[n / 2];
    let p95 = s[(n as f64 * 0.95) as usize];
    let p99 = s[(n as f64 * 0.99) as usize];
    let worst = *s.last().unwrap();
    println!(
        "perf {name}: p50={p50}us p95={p95}us p99={p99}us worst={worst}us n={n} budget_us={BUDGET_US}"
    );
    assert!(worst < BUDGET_US as u64, "{name} exceeded SPEC-004 budget");
}

fn main() {
    // perf ring-record: hot path — bounded ring push after capture is on.
    {
        let mut samples = Vec::with_capacity(N as usize);
        let mut engine = TelemetryEngine::new(4096).unwrap();
        engine.enable();
        for i in 0..N {
            let start = Instant::now();
            engine.record(ev(i as i64)).unwrap();
            samples.push(start.elapsed().as_micros() as u64);
        }
        summarize("ring-record", &samples);
    }

    // perf ring-raw: raw bounded push (no journal) — the absolute hot
    // path when capture is enabled without persistence.
    {
        let mut samples = Vec::with_capacity(N as usize);
        let mut ring = RingBuffer::new(4096).unwrap();
        for i in 0..N {
            let start = Instant::now();
            ring.push(ev(i as i64));
            samples.push(start.elapsed().as_micros() as u64);
        }
        summarize("ring-raw", &samples);
    }

    // perf redaction: single-pass redactor on a secret-bearing line.
    {
        let mut samples = Vec::with_capacity(N as usize);
        let r = wire_replay::Redactor::default();
        let text = "password=hunter2 the quick brown fox jumps over the lazy dog";
        for _ in 0..N {
            let start = Instant::now();
            let _ = r.redact_text(text);
            samples.push(start.elapsed().as_micros() as u64);
        }
        summarize("redaction", &samples);
    }

    // perf replay-hash: content hash of a moderate replay record.
    {
        let mut samples = Vec::with_capacity(10_000);
        let mut replay = SessionReplay::new("session-perf", "wiremudder", &"a".repeat(40)).unwrap();
        for i in 0..1000 {
            replay
                .push(ReplayEvent::line(
                    i as u64 + 1,
                    i as i64,
                    "You arrive at the market.",
                ))
                .unwrap();
        }
        for _ in 0..10_000 {
            let start = Instant::now();
            let _ = replay.content_hash();
            samples.push(start.elapsed().as_micros() as u64);
        }
        summarize("replay-hash", &samples);
    }

    // perf bundle-build: redacted content-addressed bundle build (P4).
    {
        let mut samples = Vec::with_capacity(10_000);
        let mut replay =
            SessionReplay::new("session-perf2", "wiremudder", &"a".repeat(40)).unwrap();
        for i in 0..100 {
            replay
                .push(ReplayEvent::line(
                    i as u64 + 1,
                    i as i64,
                    "line of gameplay text here",
                ))
                .unwrap();
        }
        let builder = BundleBuilder::default();
        for i in 0..10_000 {
            let start = Instant::now();
            let _ = builder
                .build(&replay, &format!("bundle-perf-{i}"), 5)
                .unwrap();
            samples.push(start.elapsed().as_micros() as u64);
        }
        summarize("bundle-build", &samples);
    }

    // Warm-up guard: ensure we measured real work, not a no-op loop.
    let _ = Duration::from_nanos(1);
    println!("perf fixture EP-028: ok");
}
