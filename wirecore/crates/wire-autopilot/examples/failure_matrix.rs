//! EP-019 M4: forced failure matrix for the guarded autopilot.
//!
//! Disabled, profile mismatch, stale state, rate limit, queue full,
//! denied policy, malformed input, not-found, cancel of missing proposal,
//! emergency stop, and safe user messages. No mock of the component being
//! proven; all failures are real crate behavior.
//!
//! Run: cargo run --example failure_matrix (in wire-autopilot).

use wire_actions::GateContext;
use wire_autopilot::{
    AutopilotConfig, AutopilotEngine, AutopilotError, AutopilotMode, StaleReason,
};
use wire_policy::{CommandDatabase, CommandRule, HumanTempo, RiskTier};

fn db() -> CommandDatabase {
    let mut db = CommandDatabase::new("midkemia");
    db.add_rule(CommandRule::new("say", RiskTier::Safe));
    db.add_rule(CommandRule::new("kill", RiskTier::Destructive));
    db.add_rule(CommandRule::new("quit", RiskTier::Destructive).deny());
    db
}

fn main() {
    // 1. Disabled: propose refused (off by default).
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia"),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    assert!(matches!(
        e.propose("midkemia", "say hi", &GateContext::ready()),
        Err(AutopilotError::NotEnabled)
    ));

    // 2. Profile mismatch.
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia").with_mode(AutopilotMode::ConfirmEvery),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").unwrap();
    assert!(matches!(
        e.propose("other", "say hi", &GateContext::ready()),
        Err(AutopilotError::ProfileMismatch)
    ));

    // 3. Stale state pauses.
    e.set_stale(StaleReason::CommandPolicyStale);
    assert!(matches!(
        e.propose("midkemia", "say hi", &GateContext::ready()),
        Err(AutopilotError::StaleState(StaleReason::CommandPolicyStale))
    ));
    e.clear_stale();

    // 4. Rate limit.
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia")
            .with_mode(AutopilotMode::ConfirmEvery)
            .with_rate_limit(2, 60_000),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").unwrap();
    let _ = e.propose("midkemia", "say a", &GateContext::ready()).unwrap();
    let _ = e.propose("midkemia", "say b", &GateContext::ready()).unwrap();
    assert!(matches!(
        e.propose("midkemia", "say c", &GateContext::ready()),
        Err(AutopilotError::RateLimited)
    ));

    // 5. Queue full.
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia")
            .with_mode(AutopilotMode::ConfirmEvery)
            .with_queue_capacity(2),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").unwrap();
    let _ = e.propose("midkemia", "say a", &GateContext::ready()).unwrap();
    let _ = e.propose("midkemia", "say b", &GateContext::ready()).unwrap();
    assert!(matches!(
        e.propose("midkemia", "say c", &GateContext::ready()),
        Err(AutopilotError::QueueFull)
    ));

    // 6. Denied policy (hard-deny command).
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia").with_mode(AutopilotMode::ConfirmEvery),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").unwrap();
    assert!(matches!(
        e.propose("midkemia", "quit", &GateContext::ready()),
        Err(AutopilotError::Policy(_))
    ));

    // 7. Malformed input: empty suggestion is rejected by the gateway.
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia").with_mode(AutopilotMode::ConfirmEvery),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").unwrap();
    assert!(e.propose("midkemia", "   ", &GateContext::ready()).is_err());

    // 8. Confirm/cancel of a missing proposal -> NotFound.
    assert!(matches!(
        e.confirm_and_send("ap-nope", &GateContext::ready(), |c| Ok(c.to_string())),
        Err(AutopilotError::NotFound)
    ));
    assert!(matches!(
        e.cancel("ap-nope"),
        Err(AutopilotError::NotFound)
    ));

    // 9. Auto-send outside allowlist mode -> Policy.
    assert!(matches!(
        e.auto_send("ap-nope", &GateContext::ready(), |c| Ok(c.to_string())),
        Err(AutopilotError::Policy(_))
    ));

    // 10. Emergency stop blocks and cancels.
    let id = e.propose("midkemia", "say hi", &GateContext::ready()).unwrap();
    e.emergency_stop();
    assert!(e.emergency_stop_engaged());
    assert_eq!(e.pending_count(), 0);
    assert!(e.propose("midkemia", "say no", &GateContext::ready()).is_err());

    // 11. Safe user messages leak nothing.
    for msg in [
        AutopilotError::NotEnabled.user_message(),
        AutopilotError::ProfileMismatch.user_message(),
        AutopilotError::StaleState(StaleReason::ApprovalStale).user_message(),
        AutopilotError::RateLimited.user_message(),
        AutopilotError::QueueFull.user_message(),
        AutopilotError::NotFound.user_message(),
        AutopilotError::Policy("denied".into()).user_message(),
    ] {
        assert!(!msg.contains('/'), "path leaked: {msg}");
        assert!(!msg.contains("stack"), "stack leaked: {msg}");
        assert!(!msg.contains("lib.rs"), "source leaked: {msg}");
    }

    println!("failure matrix: ok");
}
