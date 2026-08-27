//! EP-016 M3 integration flow: exercise the real provider boundary.
//!
//! States proven against real components:
//! - ready: adapter constructed with normalized capability metadata
//! - disabled: uncertified remote adapter denies by policy (acceptance #6)
//! - denied: router denies remote when privacy blocks egress (R08)
//! - degraded: router selects local explicitly when remote is blocked (R06)
//! - canceled: cancellation is distinct from failure (R07)
//! - unavailable: provider down returns a typed error without hanging
//! - error: corrupt payloads produce typed Corrupt errors
//! - privacy: redaction runs before any provider sees the request (R03)
//!
//! The live provider section calls the real local Ollama (127.0.0.1:11434).
//! It is skipped when the provider is not running; the rest still runs so
//! gameplay never depends on AI availability.

use std::time::Duration;
use wire_ai_router::{AiRouter, EvaluationFixture, EvaluationLimits, RouteConfig, RoutingInputs};
use wire_privacy::PrivacyMode;
use wire_provider_adapters::{
    AdapterError, DisabledRemoteAdapter, OllamaAdapter, ProviderAdapter, RequestRedactor,
};

fn main() {
    // -- ready -------------------------------------------------------------
    let adapter = OllamaAdapter::new("127.0.0.1", 11434, "tinyllama", 2048, 512)
        .with_timeout(30_000);
    let caps = adapter.capabilities();
    assert!(caps.streaming && caps.cancellation && caps.usage && caps.health);
    assert_eq!(format!("{:?}", caps.kind), "Local");
    println!("STATE ready: ok");

    // -- privacy (R03): redaction before the provider sees the request ------
    let redactor = RequestRedactor::new();
    let safe = redactor
        .redact_request("tell alice the vault code is sk-test-99999999")
        .expect("redaction");
    assert!(!safe.contains("sk-test-99999999"));
    assert!(!safe.contains("the vault code"));
    assert!(safe.contains("[REDACTED:"));
    println!("STATE privacy: ok");

    // -- disabled (acceptance #6) ------------------------------------------
    let remote = DisabledRemoteAdapter::new("remote-placeholder", "unset", "https://api.invalid");
    let req = wire_provider_adapters::CompletionRequest {
        request_id: "rq-integ-1".into(),
        feature: "suggest".into(),
        system: None,
        prompt: "hello".into(),
        max_tokens: 16,
        temperature: None,
        stream: false,
    };
    match remote.complete(&req) {
        Err(AdapterError::Policy(_)) => println!("STATE disabled: ok"),
        other => panic!("expected policy denial, got {other:?}"),
    }

    // -- router: default config means AI disabled (uncertified) -------------
    let cfg = std::fs::read_to_string("config/wiremudder/providers/routing-policy.example.json")
        .expect("routing policy");
    let v: serde_json::Value = serde_json::from_str(&cfg).expect("policy json");
    let mut routes = Vec::new();
    for r in v["routes"].as_array().unwrap() {
        routes.push(RouteConfig {
            route_id: r["route_id"].as_str().unwrap().into(),
            provider_id: r["provider_id"].as_str().unwrap().into(),
            kind: r["kind"].as_str().unwrap().into(),
            model: r["model"].as_str().unwrap().into(),
            certified: r["certified"].as_bool().unwrap(),
            configured: r["configured"].as_bool().unwrap(),
            remote_egress: r["remote_egress"].as_bool().unwrap(),
            context_window: r["context_window"].as_u64().unwrap() as usize,
            cost_per_1k: r["cost_per_1k"].as_f64().unwrap(),
            locality: r["locality"].as_str().unwrap().into(),
            min_privacy_mode: Some(PrivacyMode::RemoteApproved),
            est_latency_ms: r["est_latency_ms"].as_u64().unwrap(),
        });
    }
    let router = AiRouter::new(routes);
    let inputs = RoutingInputs::new("suggest", 2, PrivacyMode::LocalPreferred, 2_000, 0.1, 512);
    let d = router.route(&inputs);
    assert!(d.route_id().is_none(), "uncertified route must not be selected");
    println!("STATE disabled-route: ok ({})", d.reason());

    // -- denied (R08): privacy blocks remote, route exists ------------------
    let mut remote_route = RouteConfig::remote("remote-x", "openai", "gpt-x", 8192, 0.01, 800);
    remote_route.configured = true;
    remote_route.certified = true;
    let router2 = AiRouter::new(vec![remote_route]);
    let d2 = router2.route(&RoutingInputs::new(
        "suggest", 2, PrivacyMode::LocalOnly, 2_000, 0.1, 512,
    ));
    assert!(d2.route_id().is_none());
    assert!(d2.reason().contains("privacy"));
    println!("STATE denied: ok");

    // -- degraded (R06): remote blocked, local selected explicitly ----------
    let mut remote3 = RouteConfig::remote("remote-x", "openai", "gpt-x", 8192, 0.01, 800);
    remote3.configured = true;
    remote3.certified = true;
    let local = RouteConfig::local("ollama-local", "ollama", "tinyllama", 2048, 0.0, 30);
    let router3 = AiRouter::new(vec![remote3, local]);
    let d3 = router3.route(&RoutingInputs::new(
        "suggest", 2, PrivacyMode::LocalOnly, 2_000, 0.1, 512,
    ));
    match d3 {
        wire_ai_router::RoutingDecision::Selected { route_id, degraded, .. } => {
            assert_eq!(route_id, "ollama-local");
            assert!(degraded, "fallback must be explicit");
            println!("STATE degraded: ok");
        }
        other => panic!("expected degraded selection, got {other:?}"),
    }

    // -- unavailable: provider down returns typed error, no hang ------------
    let dead = OllamaAdapter::new("127.0.0.1", 1, "tinyllama", 2048, 512).with_timeout(2_000);
    match dead.complete(&req) {
        Err(AdapterError::Unavailable(_)) => println!("STATE unavailable: ok"),
        other => panic!("expected unavailable, got {other:?}"),
    }

    // -- canceled (R07): distinct from failure -------------------------------
    let cancelable = OllamaAdapter::new("127.0.0.1", 11434, "tinyllama", 2048, 512);
    cancelable.cancel().unwrap();
    match cancelable.complete(&req) {
        Err(AdapterError::Cancelled { .. }) => println!("STATE canceled: ok"),
        other => panic!("expected cancelled, got {other:?}"),
    }

    // -- error: corrupt payload is a typed Corrupt error ---------------------
    match wire_provider_adapters::parse_chat_response("not-json") {
        Err(AdapterError::Corrupt(_)) => println!("STATE error: ok"),
        other => panic!("expected corrupt, got {other:?}"),
    }

    // -- evaluation fixture (R10) -------------------------------------------
    let fx = EvaluationFixture {
        fixture_id: "fx-live-1".into(),
        route_id: "ollama-local".into(),
        provider: "ollama".into(),
        quality_score: 0.95,
        privacy_leak_count: 0,
        latency_ms: 0,
        cancellation_ms: 0,
        cost: 0.0,
        fallback_count: 0,
        baseline_quality: 1.0,
    };
    let rep = wire_ai_router::evaluate_fixture(&fx, &EvaluationLimits::strict());
    assert!(rep.privacy_ok);
    println!("STATE evaluation: ok");

    // -- live provider: real request through the real adapter ----------------
    // Skipped gracefully when Ollama is down (gameplay never depends on AI).
    if let Ok(health) = adapter.health() {
        if health.healthy {
            let live_req = wire_provider_adapters::CompletionRequest {
                request_id: "rq-live-1".into(),
                feature: "suggest".into(),
                system: Some("Answer in one short word.".into()),
                prompt: "state a color".into(),
                max_tokens: 16,
                temperature: None,
                stream: false,
            };
            let started = std::time::Instant::now();
            let resp = adapter.complete(&live_req).expect("live ollama completion");
            assert!(!resp.text.is_empty());
            assert_eq!(resp.usage.provider_id, "ollama");
            assert!(resp.usage.latency_ms < 30_000);
            println!(
                "LIVE complete: ok ({} chars, {} prompt tokens, {} ms)",
                resp.text.chars().count(),
                resp.usage.prompt_tokens,
                resp.usage.latency_ms
            );
            let _ = started.elapsed();

            // streaming round-trip (real NDJSON stream)
            let mut chunks = 0usize;
            let mut text = String::new();
            let streamed = adapter
                .stream(&live_req, &mut |c| {
                    chunks += 1;
                    if !c.delta.is_empty() {
                        text.push_str(&c.delta);
                    }
                })
                .expect("live ollama stream");
            assert!(streamed.streamed);
            println!(
                "LIVE stream: ok ({} chunks, {} chars)",
                chunks,
                text.chars().count()
            );

            // usage was recorded by the adapter
            let usage = adapter.usage().expect("usage log");
            assert!(usage.len() >= 2);
            println!("LIVE usage: ok ({} records)", usage.len());
        } else {
            println!("LIVE skipped: provider healthy=false");
        }
    } else {
        println!("LIVE skipped: provider unavailable");
    }

    println!("INTEGRATION_FLOW_DONE");
    let _ = Duration::from_secs(0);
}
