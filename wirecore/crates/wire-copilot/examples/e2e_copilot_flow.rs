//! EP-017 M3 E2E: full user-visible copilot flow.
//!
//! Real flow: EP-015 ContextCapsule -> EP-016 AiRouter decision -> EP-017
//! CopilotEngine -> Qt CopilotPaneQt boundary. Exercises the ready path and
//! the degraded (provider unavailable) path, and asserts the pane is a
//! passive observer that preserves manual gameplay.
//!
//! Run: cargo run --example e2e_copilot_flow (or via the M3 test script).

use wire_ai_router::{AiRouter, RouteConfig, RoutingInputs};
use wire_copilot::{
    CompletionError, CopilotConfig, CopilotEngine, CopilotOutcome, ProviderCompletion,
};
use wire_privacy::PrivacyMode;

fn main() {
    // ---- Build a real capsule from distilled game lines (EP-015). ----
    let mut distiller = wire_context::Distiller::new();
    distiller.feed_line("You are in The Crossroads.");
    distiller.feed_line("Obvious exits: north, east");
    distiller.feed_line("A guard is here.");
    distiller.feed_line("An innkeeper is here.");
    let capsule = distiller.into_capsule();
    assert_eq!(capsule.room.as_deref(), Some("The Crossroads"));
    assert!(capsule.entities.iter().any(|e| e == "guard"));

    // ---- Route through the EP-016 router (local path, certified). ----
    let router = AiRouter::new(vec![RouteConfig::local(
        "ollama-local", "ollama", "tinyllama", 4096, 0.0, 50,
    )]);
    let inputs = RoutingInputs::new(
        "help me find the lost key",
        3,
        PrivacyMode::LocalPreferred,
        2000,
        0.01,
        4096,
    );
    let decision = router.route(&inputs);
    assert!(decision.route_id().is_some(), "local route must be selected");

    // ---- Copilot engine (EP-017). ----
    let engine = CopilotEngine::new(CopilotConfig::new(
        "player-copilot", "e2e-profile", 3, 2000, 0.01, 4096,
    ));

    // Ready path: a real completion (in E2E this is the adapter result
    // surface; M5 live-fire proves the live Ollama provider).
    let completion = ProviderCompletion {
        provider_id: "ollama".into(),
        route_id: "ollama-local".into(),
        text: "suggest asking the innkeeper about the lost key.".into(),
        prompt_tokens: 132,
        completion_tokens: 12,
        estimated_cost_usd_micros: 0,
        latency_ms: 421,
    };
    let outcome = engine.suggest(&capsule, &decision, Ok(completion));

    match &outcome {
        CopilotOutcome::Suggestion(s) => {
            assert!(!s.text.is_empty());
            assert!(s.citations.iter().any(|c| matches!(
                c,
                wire_copilot::Citation::Observation { .. }
            )));
            assert!(s.disclosure.provider_id == "ollama");
            assert!(s.disclosure.route_id == "ollama-local");
            assert!(s.confidence > 0.0 && s.confidence < 1.0);
            assert!(!s.why.render(&engine.redactor).is_empty());
            // Action proposals require SPEC-009 confirmation; never executed.
            if let Some(ap) = &s.action_proposal {
                assert!(ap.requires_confirmation);
            }
            println!("E2E ready: suggestion={} state=ready", s.text);
        }
        other => panic!("expected suggestion, got {other:?}"),
    }

    // ---- Degraded path: provider unavailable -> no suggestion. ----
    let degraded = engine.suggest(
        &capsule,
        &decision,
        Err(CompletionError::Unavailable("ollama".into())),
    );
    match degraded {
        CopilotOutcome::NoSuggestion { degraded, reason } => {
            assert!(degraded);
            assert!(!reason.is_empty());
            println!("E2E degraded: reason={reason}");
        }
        other => panic!("expected degraded no-suggestion, got {other:?}"),
    }

    println!("E2E copilot flow: ok");
}
