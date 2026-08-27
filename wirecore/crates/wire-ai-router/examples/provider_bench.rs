//! EP-016 M4 performance fixture: deterministic core-path latency.
//!
//! Workload: redaction, routing (10k route table), payload build, and
//! response parse. Release build. Prints hardware/workload/distributions
//! as raw evidence; fails when any budget is exceeded.

use std::time::{Duration, Instant};
use wire_ai_router::{AiRouter, RouteConfig, RoutingInputs};
use wire_privacy::PrivacyMode;
use wire_provider_adapters::{RequestRedactor, build_chat_payload, parse_chat_response};

fn bench<F: FnMut()>(name: &str, budget_ms: f64, mut f: F) {
    // warmup
    for _ in 0..200 {
        f();
    }
    const N: usize = 20_000;
    let mut samples = Vec::with_capacity(N);
    for _ in 0..N {
        let t0 = Instant::now();
        f();
        samples.push(t0.elapsed().as_secs_f64() * 1e6); // micros
    }
    samples.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let p50 = samples[N / 2];
    let p95 = samples[(N as f64 * 0.95) as usize];
    let p99 = samples[(N as f64 * 0.99) as usize];
    let max = samples[N - 1];
    println!(
        "PERF {name}: p50={p50:.4}us p95={p95:.4}us p99={p99:.4}us max={max:.4}us n={N}"
    );
    if p95 / 1000.0 > budget_ms {
        panic!("{name} p95 {:.4}ms exceeds budget {budget_ms}ms", p95 / 1000.0);
    }
}

fn main() {
    println!("PERF host: {}", std::env::consts::OS);
    println!("PERF workload: redact/router/payload/parse core paths");

    let redactor = RequestRedactor::new();
    let dirty = "tell alice the key is sk-liveABC123DEF456\nlogin bob s3cr3t\npassword= hunter2\nrouting_secret= rot13";
    bench("redact", 0.1, || {
        let _ = redactor.redact_request(dirty).unwrap();
    });

    let mut routes = Vec::with_capacity(10_000);
    for i in 0..10_000 {
        routes.push(RouteConfig::local(
            &format!("local-{i:05}"),
            "ollama",
            "tinyllama",
            2048,
            (i % 100) as f64 / 1000.0,
            10 + (i % 50) as u64,
        ));
    }
    let router = AiRouter::new(routes);
    let inputs = RoutingInputs::new("suggest", 2, PrivacyMode::LocalPreferred, 2_000, 0.1, 512);
    bench("route-10k", 0.5, || {
        let _ = router.route(&inputs);
    });

    let body = r#"{"model":"tinyllama","message":{"role":"assistant","content":"sure"},"done":true,"prompt_eval_count":12,"eval_count":3}"#;
    bench("parse-response", 0.05, || {
        let _ = parse_chat_response(body).unwrap();
    });

    bench("build-payload", 0.05, || {
        let _ = build_chat_payload("tinyllama", Some("sys"), "prompt text here", 64, false);
    });

    println!("PERF_MATRIX_DONE");
    let _ = Duration::from_millis(0);
}
