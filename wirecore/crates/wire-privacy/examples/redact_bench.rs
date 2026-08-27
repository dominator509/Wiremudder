//! Redaction throughput benchmark (SPEC-004). Redacts a 1 MiB text
//! with the configured patterns and prints JSON evidence to stdout.

use std::time::Instant;
use wire_privacy::{RedactionEngine, RedactionPattern};

fn main() {
    let mut eng = RedactionEngine::new(true);
    eng.add_pattern(
        RedactionPattern::new("t1", "token", r"(?i)sk-[a-z0-9]{16,}", "[REDACTED]").unwrap(),
    );
    eng.add_pattern(
        RedactionPattern::new("t2", "pem", r"-----BEGIN [A-Z ]*PRIVATE KEY-----", "[REDACTED]").unwrap(),
    );
    eng.add_pattern(
        RedactionPattern::new("t3", "pwd", r"(?i)password\s*[:=]\s*\S+", "[REDACTED]").unwrap(),
    );

    let chunk = "user=alice password=hunter2 token=sk-abcdefghijklmnop xxxxxxxxxx\n".repeat(16 * 1024);
    let text = chunk.repeat(16); // ~1 MiB
    let n = text.len();

    // Warm up.
    let _ = eng.redact(&text);

    let mut samples = Vec::new();
    for _ in 0..5 {
        let t0 = Instant::now();
        let out = eng.redact(&text);
        samples.push(t0.elapsed().as_secs_f64() * 1000.0);
        assert!(!out.contains("hunter2"));
    }
    samples.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let p50 = samples[2];
    let p95 = samples[4];
    let mbps = (n as f64 / (1024.0 * 1024.0)) / (p50 / 1000.0);

    println!(
        "{{\"bytes\":{},\"p50_ms\":{:.3},\"p95_ms\":{:.3},\"throughput_mib_per_s\":{:.1}}}",
        n, p50, p95, mbps
    );
}
