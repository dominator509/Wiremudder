//! EP-019 M3 E2E: full guarded-autopilot user-visible flow.
//!
//! Proposes a safe action (visible, approved), a destructive action
//! (visible, awaiting confirmation), confirms the destructive action
//! (user-approved send), cancels another, exercises stale-state pause and
//! emergency stop, and verifies the visible queue + complete audit. All
//! through the real crates (wire-autopilot -> wire-actions -> wire-policy).
//!
//! Run: cargo run --example e2e_autopilot_flow

use wire_actions::GateContext;
use wire_autopilot::{
    AutopilotConfig, AutopilotEngine, AutopilotMode, AutopilotStatus, StaleReason,
};
use wire_policy::{CommandDatabase, CommandRule, HumanTempo, RiskTier};

fn db() -> CommandDatabase {
    let mut db = CommandDatabase::new("midkemia");
    db.add_rule(CommandRule::new("say", RiskTier::Safe));
    db.add_rule(CommandRule::new("tell", RiskTier::Standard));
    db.add_rule(CommandRule::new("kill", RiskTier::Destructive));
    db.add_rule(CommandRule::new("quit", RiskTier::Destructive).deny());
    db
}

fn main() {
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia").with_mode(AutopilotMode::ConfirmEvery),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );

    // Off by default.
    assert_eq!(e.status(), AutopilotStatus::Disabled);

    // Enable for the profile.
    e.enable("midkemia").expect("enable");
    assert_eq!(e.status(), AutopilotStatus::Ready);

    // 1. Safe action: visible approved proposal; confirm sends through the
    //    deterministic gateway.
    let id_say = e
        .propose("midkemia", "say hello", &GateContext::ready())
        .expect("propose say");
    assert_eq!(e.pending_count(), 1, "action must be visible before send");
    let p = e.pending().next().unwrap();
    assert!(!p.requires_confirmation);
    assert_eq!(p.status, "approved-visible");
    let r = e
        .confirm_and_send(&id_say, &GateContext::ready(), |c| Ok(format!("sent:{c}")))
        .expect("confirm say");
    assert_eq!(r, "sent");

    // 2. Destructive action: visible awaiting confirmation; confirmation
    //    makes the send user-approved.
    let id_kill = e
        .propose("midkemia", "kill orc", &GateContext::ready())
        .expect("propose kill");
    let p = e.pending().next().unwrap();
    assert!(p.requires_confirmation);
    assert_eq!(p.status, "awaiting-confirmation");
    let r = e
        .confirm_and_send(&id_kill, &GateContext::ready(), |c| Ok(format!("sent:{c}")))
        .expect("confirm kill");
    assert_eq!(r, "sent-confirmed", "confirmed send is user-approved");

    // 3. Cancel a pending action (pause/cancel).
    let id_cancel = e
        .propose("midkemia", "tell guard hi", &GateContext::ready())
        .expect("propose tell");
    assert_eq!(e.pending_count(), 1);
    e.cancel(&id_cancel).expect("cancel");
    assert_eq!(e.pending_count(), 0);

    // 4. Stale state pauses; no new proposals while paused.
    e.set_stale(StaleReason::RouteStale);
    assert!(matches!(e.status(), AutopilotStatus::Paused(StaleReason::RouteStale)));
    assert!(e
        .propose("midkemia", "say hi", &GateContext::ready())
        .is_err());
    e.clear_stale();
    assert_eq!(e.status(), AutopilotStatus::Ready);

    // 5. Emergency stop cancels queued automation and blocks new proposals.
    let id_estop = e
        .propose("midkemia", "say bye", &GateContext::ready())
        .expect("propose estop");
    assert_eq!(e.pending_count(), 1);
    e.emergency_stop();
    assert!(e.emergency_stop_engaged());
    assert_eq!(e.pending_count(), 0);
    let _ = id_estop; // cancelled by the emergency stop
    assert!(e
        .propose("midkemia", "say nope", &GateContext::ready())
        .is_err());

    // 6. Complete audit: proposed -> sent (approved), proposed -> sent
    //    (confirmed), proposed -> cancelled, paused, emergency-stop.
    let audit = e.audit_log();
    assert!(audit.iter().any(|a| a.action == "sent" && a.detail.starts_with("sent:")));
    assert!(audit
        .iter()
        .any(|a| a.action == "sent" && a.detail.starts_with("confirmed:")));
    assert!(audit.iter().any(|a| a.action == "cancelled"));
    assert!(audit.iter().any(|a| a.action == "paused"));
    assert!(audit.iter().any(|a| a.action == "emergency-stop"));

    // 7. No hidden send: every sent proposal was first visible in the queue.
    let proposed_visible = audit
        .iter()
        .filter(|a| a.action == "proposed" && a.detail == "visible")
        .count();
    assert!(proposed_visible >= 2, "every send must first be visible");

    println!("E2E autopilot: ok");
}
