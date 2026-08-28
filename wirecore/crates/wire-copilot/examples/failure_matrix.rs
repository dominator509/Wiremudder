//! EP-017 M4: forced failure matrix through the real CopilotEngine.
//!
//! Each SPEC-025 failure class must produce NoSuggestion{degraded:true}
//! with a safe user message and no secret leakage. Uses the real engine
//! path (not mocks): completion errors are the typed surface the provider
//! adapters (EP-016) produce on real failures.
//!
//! Run: cargo run --example failure_matrix

use wire_ai_router::{AiRouter, RouteConfig, RoutingInputs};
use wire_context::Distiller;
use wire_copilot::{
    CompletionError, CopilotConfig, CopilotEngine, CopilotOutcome, ProviderCompletion,
};
use wire_privacy::PrivacyMode;

fn capsule() -> wire_context::ContextCapsule {
    let mut d = Distiller::new();
    d.feed_line("You are in The Crossroads.");
    d.feed_line("A guard is here.");
    d.feed_line("suggest talking to the guard"); // player request
    d.into_capsule()
}

fn decision() -> wire_ai_router::RoutingDecision {
    let router = AiRouter::new(vec![RouteConfig::local(
        "ollama-local", "ollama", "tinyllama", 4096, 0.0, 50,
    )]);
    router.route(&RoutingInputs::new(
        "help", 3, PrivacyMode::LocalPreferred, 2000, 0.01, 4096,
    ))
}

fn main() {
    let engine = CopilotEngine::new(CopilotConfig::new(
        "player-copilot", "failure-profile", 3, 2000, 0.01, 4096,
    ));
    let cap = capsule();
    let dec = decision();

    // 1. Dependency unavailable (SPEC-025-R01/R04).
    let out = engine.suggest(
        &cap,
        &dec,
        Err(CompletionError::Unavailable("ollama".into())),
    );
    match out {
        CopilotOutcome::NoSuggestion { degraded, reason } => {
            assert!(degraded);
            assert_eq!(reason, "provider is unavailable");
        }
        other => panic!("unavailable: expected NoSuggestion, got {other:?}"),
    }

    // 2. Timeout.
    let out = engine.suggest(&cap, &dec, Err(CompletionError::Timeout("ollama".into())));
    match out {
        CopilotOutcome::NoSuggestion { degraded, reason } => {
            assert!(degraded);
            assert!(reason.contains("did not respond"));
        }
        other => panic!("timeout: expected NoSuggestion, got {other:?}"),
    }

    // 3. Cancellation (distinct from failure, SPEC-025-R07).
    let out = engine.suggest(&cap, &dec, Err(CompletionError::Cancelled("ollama".into())));
    match out {
        CopilotOutcome::NoSuggestion { degraded, reason } => {
            assert!(degraded);
            assert!(reason.contains("cancelled"));
        }
        other => panic!("cancel: expected NoSuggestion, got {other:?}"),
    }

    // 4. Malformed/oversized provider payload -> protocol error.
    let out = engine.suggest(&cap, &dec, Err(CompletionError::Protocol("ollama".into())));
    match out {
        CopilotOutcome::NoSuggestion { degraded, reason } => {
            assert!(degraded);
            assert!(reason.contains("invalid response"));
        }
        other => panic!("protocol: expected NoSuggestion, got {other:?}"),
    }

    // 5. Oversized suggestion: engine truncates + redacts (bounded).
    let huge = ProviderCompletion {
        provider_id: "ollama".into(),
        route_id: "ollama-local".into(),
        text: "sk-abcdef1234567890 ".repeat(500),
        prompt_tokens: 10,
        completion_tokens: 5000,
        estimated_cost_usd_micros: 7,
        latency_ms: 900,
    };
    let out = engine.suggest(&cap, &dec, Ok(huge));
    match out {
        CopilotOutcome::Suggestion(s) => {
            assert!(s.text.chars().count() <= 603);
            assert!(!s.text.contains("abcdef1234567890"));
            assert!(s.text.contains("[REDACTED]"));
            assert!(s.disclosure.completion_tokens == 5000);
        }
        other => panic!("oversized: expected Suggestion, got {other:?}"),
    }

    // 6. Denied route (policy) -> NoSuggestion, NOT degraded (route denied).
    let denied = wire_ai_router::RoutingDecision::Denied {
        reason: "remote route not certified".into(),
    };
    let out = engine.suggest(&cap, &denied, Ok(ProviderCompletion {
        provider_id: "remote".into(),
        route_id: "remote-1".into(),
        text: "should never appear".into(),
        prompt_tokens: 1,
        completion_tokens: 1,
        estimated_cost_usd_micros: 0,
        latency_ms: 1,
    }));
    match out {
        CopilotOutcome::NoSuggestion { degraded, reason } => {
            assert!(!degraded);
            assert!(reason.contains("not certified"));
        }
        other => panic!("denied: expected NoSuggestion, got {other:?}"),
    }

    // 7. No-suggestion route decision (router said no) -> NoSuggestion.
    let no_sug = wire_ai_router::RoutingDecision::NoSuggestion {
        reason: "no route within budget".into(),
    };
    let out = engine.suggest(&cap, &no_sug, Ok(ProviderCompletion {
        provider_id: "x".into(),
        route_id: "x".into(),
        text: "should never appear".into(),
        prompt_tokens: 1,
        completion_tokens: 1,
        estimated_cost_usd_micros: 0,
        latency_ms: 1,
    }));
    match out {
        CopilotOutcome::NoSuggestion { degraded, reason } => {
            assert!(!degraded);
            assert!(reason.contains("budget"));
        }
        other => panic!("no-suggestion: expected NoSuggestion, got {other:?}"),
    }

    // 8. Duplicate/replayed request: same capsule + request twice yields
    //    identical outcomes (deterministic engine, no side effects).
    let first = engine.suggest(&cap, &dec, Ok(ProviderCompletion {
        provider_id: "ollama".into(),
        route_id: "ollama-local".into(),
        text: "suggest checking the guard post.".into(),
        prompt_tokens: 50,
        completion_tokens: 8,
        estimated_cost_usd_micros: 0,
        latency_ms: 300,
    }));
    let second = engine.suggest(&cap, &dec, Ok(ProviderCompletion {
        provider_id: "ollama".into(),
        route_id: "ollama-local".into(),
        text: "suggest checking the guard post.".into(),
        prompt_tokens: 50,
        completion_tokens: 8,
        estimated_cost_usd_micros: 0,
        latency_ms: 300,
    }));
    assert_eq!(first, second, "duplicate request must be deterministic");

    // 9. Resource exhaustion (cost budget / token budget): engine stays
    //    bounded; disclosure still reports the usage.
    let rich = ProviderCompletion {
        provider_id: "ollama".into(),
        route_id: "ollama-local".into(),
        text: "suggest searching the storeroom.".into(),
        prompt_tokens: 4000,
        completion_tokens: 2000,
        estimated_cost_usd_micros: 999_999,
        latency_ms: 5000,
    };
    let out = engine.suggest(&cap, &dec, Ok(rich));
    match out {
        CopilotOutcome::Suggestion(s) => {
            assert!(s.disclosure.estimated_cost_usd_micros == 999_999);
            assert!(s.disclosure.latency_ms == 5000);
        }
        other => panic!("exhaustion: expected Suggestion with disclosure, got {other:?}"),
    }

    println!("failure matrix: ok");
}
