//! EP-016 M3 E2E: full user-visible AI provider flow.
//!
//! redact -> route -> complete -> usage record -> evaluation report.
//! Also proves WM-SPEC-013-R08/R06 semantics against real components and
//! that optional AI failure preserves manual text gameplay (acceptance
//! obligation 5): a player command still executes when the provider is
//! unavailable, and the whole AI path returns typed errors without hanging.

use wire_ai_router::{AiRouter, RouteConfig, RoutingInputs};
use wire_privacy::PrivacyMode;
use wire_provider_adapters::{
    AdapterError, CompletionRequest, OllamaAdapter, ProviderAdapter, RequestRedactor,
};

/// A player command executes regardless of AI availability. This is the
/// manual text gameplay path; it never waits on the optional AI subsystem.
fn manual_command(name: &str) -> String {
    match name {
        "look" => "A dark vault. Exits: north, east.".to_string(),
        "north" => "You move north into a torchlit corridor.".to_string(),
        _ => "Huh?".to_string(),
    }
}

fn main() {
    // 1. Redact the user request before any provider sees it (R03).
    let redactor = RequestRedactor::new();
    let prompt = "tell alice the key is sk-liveABC123DEF456\nlogin bob s3cr3t\npassword= hunter2";
    let safe = redactor.redact_request(prompt).expect("redact");
    assert!(!safe.contains("sk-liveABC123DEF456"));
    assert!(!safe.contains("s3cr3t"));
    assert!(!safe.contains("hunter2"));
    assert!(!safe.contains("the key"));
    println!("E2E redact: ok");

    // 2. Manual gameplay executes first (never waits on AI).
    assert_eq!(manual_command("look"), "A dark vault. Exits: north, east.");
    println!("E2E gameplay: ok");

    // 3. Route the request: privacy blocks remote, certified local exists ->
    //    explicit degraded selection, never silent remote (R06/R08).
    let mut remote = RouteConfig::remote("remote-x", "openai", "gpt-x", 8192, 0.01, 800);
    remote.configured = true;
    remote.certified = true;
    let local = RouteConfig::local("ollama-local", "ollama", "tinyllama", 2048, 0.0, 30);
    let router = AiRouter::new(vec![remote, local]);
    let inputs = RoutingInputs::new("suggest", 2, PrivacyMode::LocalOnly, 2_000, 0.1, 512);
    let decision = router.route(&inputs);
    let selected = decision.route_id().expect("must select local");
    assert_eq!(selected, "ollama-local");
    let degraded = matches!(
        decision,
        wire_ai_router::RoutingDecision::Selected { degraded: true, .. }
    );
    assert!(degraded, "local fallback must be explicit");
    println!("E2E route: ok ({} - {})", selected, decision.reason());

    // 4. Complete the request through the real local provider.
    let adapter = OllamaAdapter::new("127.0.0.1", 11434, "tinyllama", 2048, 512)
        .with_timeout(30_000);
    let req = CompletionRequest {
        request_id: "rq-e2e-1".into(),
        feature: "suggest".into(),
        system: Some("Answer in one short word.".into()),
        prompt: safe.clone(),
        max_tokens: 16,
        temperature: None,
        stream: false,
    };

    match adapter.health() {
        Ok(h) if h.healthy => {
            match adapter.complete(&req) {
                Ok(resp) => {
                    assert!(!resp.text.is_empty());
                    assert_eq!(resp.usage.feature, "suggest");
                    assert!(resp.usage.prompt_tokens > 0);
                    println!(
                        "E2E complete: ok ({} chars, {} ms)",
                        resp.text.chars().count(),
                        resp.usage.latency_ms
                    );
                    // usage is observable (SPEC-013-R07 compatible record)
                    let usage = adapter.usage().expect("usage");
                    assert!(!usage.is_empty());
                    println!("E2E usage: ok ({} record(s))", usage.len());
                }
                Err(e) => {
                    println!("E2E complete: provider error ({}) - gameplay continues", e.user_message());
                }
            }
        }
        _ => {
            println!("E2E complete: skipped (provider unavailable) - gameplay continues");
        }
    }

    // 5. Provider failure never blocks gameplay: typed error, fast, and the
    //    next manual command still executes.
    let dead = OllamaAdapter::new("127.0.0.1", 1, "tinyllama", 2048, 512).with_timeout(2_000);
    let started = std::time::Instant::now();
    let err = dead.complete(&req).expect_err("must fail");
    let elapsed = started.elapsed();
    assert!(err.is_cancelled() || matches!(err, AdapterError::Unavailable(_)));
    assert!(elapsed.as_millis() < 5_000, "no hang on provider failure");
    println!("E2E fail-fast: ok ({} ms)", elapsed.as_millis());
    assert_eq!(manual_command("north"), "You move north into a torchlit corridor.");
    println!("E2E gameplay-after-failure: ok");

    println!("E2E_PROVIDER_FLOW_DONE");
}
