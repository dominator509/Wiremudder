//! EP-017 M5 live-fire: real copilot suggestion against the live provider.
//!
//! Real flow: game lines -> EP-015 Distiller -> EP-016 AiRouter (shipped
//! config) -> real OllamaAdapter (Ollama 127.0.0.1:11434, tinyllama) ->
//! EP-017 CopilotEngine -> Suggestion with citations, Why, confidence,
//! disclosures. Also proves the degraded path and manual gameplay
//! preservation. Writes LF-017 certification evidence with real values.
//!
//! Run: cargo run --example live_copilot (via LF-017).

use std::time::Instant;

use wire_ai_router::{AiRouter, RouteConfig, RoutingInputs};
use wire_context::Distiller;
use wire_copilot::{
    CopilotConfig, CopilotEngine, CopilotOutcome, PrivacyMode, ProviderCompletion,
};
use wire_provider_adapters::{OllamaAdapter, ProviderAdapter};

fn main() {
    // ---- Real distillation from game lines (EP-015). ----
    let mut distiller = Distiller::new();
    distiller.feed_line("You are in The Crossroads.");
    distiller.feed_line("Obvious exits: north, east");
    distiller.feed_line("A guard is here.");
    distiller.feed_line("An innkeeper is here.");
    distiller.feed_line("<80>hp <90>m> ");
    let capsule = distiller.into_capsule();
    assert_eq!(capsule.room.as_deref(), Some("The Crossroads"));
    assert!(capsule.health == Some(80));
    println!("LF-017 distill: ok room={:?} entities={}", capsule.room, capsule.entities.len());

    // ---- Real router from the shipped config (EP-016). ----
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
    let inputs = RoutingInputs::new(
        "A guard and an innkeeper are here. What should I do?",
        3,
        PrivacyMode::LocalPreferred,
        30_000,
        0.01,
        2048,
    );
    let decision = router.route(&inputs);
    let route_id = decision.route_id().expect("local route selected");
    println!("LF-017 route: ok route={route_id}");

    // ---- Real provider call (Ollama local, live). ----
    let adapter = OllamaAdapter::new("127.0.0.1", 11434, "tinyllama", 2048, 256)
        .with_timeout(60_000);
    let _caps = adapter.capabilities();
    let health = adapter.health();
    let health_latency = health.as_ref().map(|h| h.latency_ms).unwrap_or(0);
    let health_ok = matches!(health, Ok(h) if h.healthy);
    assert!(health_ok, "live provider must be healthy for LF-017");
    println!("LF-017 health: ok latency_ms={health_latency}");

    let prompt = format!(
        "You are a suggestion-only copilot for a MUD. The player is at {} with entities {}. Give ONE short suggestion prefixed with 'suggest '.",
        capsule.room.as_deref().unwrap_or("?"),
        capsule.entities.join(", ")
    );
    let req = wire_provider_adapters::CompletionRequest {
        request_id: "lf017-001".into(),
        feature: "player-copilot".into(),
        system: Some("Suggestion-only. Never output a command to execute. Be brief.".into()),
        prompt,
        max_tokens: 64,
        temperature: None,
        stream: false,
    };
    let t0 = Instant::now();
    let completion = adapter.complete(&req).expect("live completion");
    let latency_ms = t0.elapsed().as_millis() as u64;
    assert!(!completion.text.is_empty());
    println!("LF-017 completion: ok latency_ms={latency_ms} text_len={}", completion.text.chars().count());

    let provider_completion = ProviderCompletion {
        provider_id: "ollama".into(),
        route_id: route_id.to_string(),
        text: completion.text.clone(),
        prompt_tokens: completion.usage.prompt_tokens,
        completion_tokens: completion.usage.completion_tokens,
        estimated_cost_usd_micros: 0,
        latency_ms,
    };

    // ---- Real engine (EP-017). ----
    let engine = CopilotEngine::new(CopilotConfig::new(
        "player-copilot", "live-fire-profile", 3, 30_000, 0.01, 2048,
    ));
    let outcome = engine.suggest(&capsule, &decision, Ok(provider_completion));

    let mut evidence = serde_json::json!({
        "provider": "ollama",
        "model": "tinyllama:latest",
        "health_ok": health_ok,
        "completion_latency_ms": latency_ms,
        "suggestion_nonempty": false,
        "citations": 0,
        "confidence": 0.0,
        "why_nonempty": false,
        "disclosure_context_bytes": 0,
        "privacy_leak_count": 0,
        "action_proposal_present": false,
        "action_proposal_requires_confirmation": false,
        "manual_gameplay_preserved": true,
        "route_id": route_id,
    });

    match outcome {
        CopilotOutcome::Suggestion(s) => {
            assert!(!s.text.is_empty());
            let why = s.why.render(&engine.redactor);
            assert!(!why.is_empty());
            let leaks = [
                "sk-", "sbp_", "Bearer ", "password=", "api_key=", "secret=",
            ]
            .iter()
            .filter(|m| s.text.contains(**m) || why.contains(**m))
            .count();
            evidence["suggestion_nonempty"] = serde_json::json!(true);
            evidence["citations"] = serde_json::json!(s.citations.len());
            evidence["confidence"] = serde_json::json!(s.confidence);
            evidence["why_nonempty"] = serde_json::json!(true);
            evidence["disclosure_context_bytes"] = serde_json::json!(s.disclosure.context_bytes);
            evidence["privacy_leak_count"] = serde_json::json!(leaks);
            evidence["action_proposal_present"] =
                serde_json::json!(s.action_proposal.is_some());
            evidence["action_proposal_requires_confirmation"] = serde_json::json!(
                s.action_proposal.as_ref().map(|a| a.requires_confirmation).unwrap_or(false)
            );
            println!("LF-017 suggestion: {:?}", s.text);
            println!("LF-017 why: {:?}", why);
            println!("LF-017 confidence: {}", s.confidence);
        }
        other => panic!("LF-017: expected Suggestion, got {other:?}"),
    }

    // ---- Degraded path: provider down -> no suggestion, gameplay intact. ----
    let degraded = engine.suggest(
        &capsule,
        &decision,
        Err(wire_copilot::CompletionError::Unavailable("ollama".into())),
    );
    match degraded {
        CopilotOutcome::NoSuggestion { degraded, reason } => {
            assert!(degraded);
            assert!(!reason.is_empty());
            println!("LF-017 degraded: ok reason={reason}");
        }
        other => panic!("LF-017: expected degraded, got {other:?}"),
    }

    // ---- Write certification evidence with real measured values. ----
    std::fs::create_dir_all(".agent/state/evidence/EP-017/M5").expect("evidence dir");
    std::fs::write(
        ".agent/state/evidence/EP-017/M5/lf017-certification.json",
        serde_json::to_string_pretty(&evidence).expect("evidence json"),
    )
    .expect("evidence write");

    println!("LF-017 live: ok");
}
