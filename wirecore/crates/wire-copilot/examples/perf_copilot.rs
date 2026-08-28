//! EP-017 M4: performance fixture for the copilot engine path.
//!
//! Measures the real deterministic path: capsule build (distill), routing
//! (EP-016), and suggestion (EP-017). Records p50/p95/max over N runs and
//! asserts the SPEC-004 budget (suggestion generation is a small local
//! computation; the provider round-trip is not included here - that is
//! measured by M5 live-fire).
//!
//! Run: cargo run --release --example perf_copilot

use std::time::Instant;

use wire_ai_router::{AiRouter, RouteConfig, RoutingInputs};
use wire_context::Distiller;
use wire_copilot::{
    CopilotConfig, CopilotEngine, CopilotOutcome, PrivacyMode, ProviderCompletion,
};

const RUNS: usize = 2000;

fn main() {
    let engine = CopilotEngine::new(CopilotConfig::new(
        "player-copilot", "perf-profile", 3, 2000, 0.01, 4096,
    ));
    let router = AiRouter::new(vec![RouteConfig::local(
        "ollama-local", "ollama", "tinyllama", 4096, 0.0, 50,
    )]);

    // Warmup.
    for _ in 0..100 {
        let mut d = Distiller::new();
        d.feed_line("You are in The Crossroads.");
        let cap = d.into_capsule();
        let _ = engine.suggest(&cap, &router.route(&RoutingInputs::new(
            "help", 3, PrivacyMode::LocalPreferred, 2000, 0.01, 4096,
        )), Ok(ProviderCompletion {
            provider_id: "ollama".into(),
            route_id: "ollama-local".into(),
            text: "suggest talking to the guard.".into(),
            prompt_tokens: 50,
            completion_tokens: 8,
            estimated_cost_usd_micros: 0,
            latency_ms: 1,
        }));
    }

    let mut times = Vec::with_capacity(RUNS);
    for _ in 0..RUNS {
        let t0 = Instant::now();
        let mut d = Distiller::new();
        d.feed_line("You are in The Crossroads.");
        d.feed_line("A guard is here.");
        d.feed_line("An innkeeper is here.");
        let cap = d.into_capsule();
        let dec = router.route(&RoutingInputs::new(
            "help me find the key", 3, PrivacyMode::LocalPreferred, 2000, 0.01, 4096,
        ));
        let out = engine.suggest(&cap, &dec, Ok(ProviderCompletion {
            provider_id: "ollama".into(),
            route_id: "ollama-local".into(),
            text: "suggest asking the innkeeper.".into(),
            prompt_tokens: 50,
            completion_tokens: 8,
            estimated_cost_usd_micros: 0,
            latency_ms: 1,
        }));
        assert!(matches!(out, CopilotOutcome::Suggestion(_)));
        times.push(t0.elapsed().as_nanos() as u64);
    }

    times.sort_unstable();
    let p50 = times[RUNS / 2];
    let p95 = times[(RUNS as f64 * 0.95) as usize];
    let max = *times.last().unwrap();
    let mean = times.iter().sum::<u64>() / RUNS as u64;

    println!("perf: runs={RUNS} mean_ns={mean} p50_ns={p50} p95_ns={p95} max_ns={max}");

    // Budget: SPEC-004 - suggestion generation is a small local operation;
    // budget 1ms per suggestion (provider round-trip measured separately).
    let budget_ns = 1_000_000u64;
    assert!(p95 < budget_ns, "p95 {p95}ns exceeds budget {budget_ns}ns");
    println!("perf fixture: ok");
}
