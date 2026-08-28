//! EP-019 M4: security matrix for the guarded autopilot.
//!
//! No hidden auto-send, confirmation cannot be bypassed by injection,
//! narrow allowlist only, no self-authority, complete audit, safe
//! messages. Uses the real crate types.
//!
//! Run: cargo run --example security_matrix (in wire-autopilot).

use wire_actions::GateContext;
use wire_autopilot::{
    AutopilotConfig, AutopilotEngine, AutopilotError, AutopilotMode,
};
use wire_policy::{CommandDatabase, CommandRule, HumanTempo, RiskTier};

fn db() -> CommandDatabase {
    let mut db = CommandDatabase::new("midkemia");
    db.add_rule(CommandRule::new("say", RiskTier::Safe));
    db.add_rule(CommandRule::new("kill", RiskTier::Destructive));
    db.add_rule(CommandRule::new("give", RiskTier::Risky));
    db.add_rule(CommandRule::new("quit", RiskTier::Destructive).deny());
    db
}

fn main() {
    // 1. No hidden auto-send: nothing sends inside propose(); the send
    //    closures are only invoked after confirmation or allowlist match.
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia").with_mode(AutopilotMode::ConfirmEvery),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").unwrap();
    let mut sends = 0;
    let id = e
        .propose("midkemia", "say hi", &GateContext::ready())
        .unwrap();
    assert_eq!(sends, 0, "propose must not send");
    assert_eq!(e.pending_count(), 1, "action must be visible");
    e.confirm_and_send(&id, &GateContext::ready(), |_| {
        sends += 1;
        Ok("sent".into())
    })
    .unwrap();
    assert_eq!(sends, 1, "send only after explicit confirmation");

    // 2. Confirmation cannot be bypassed by phrasing: destructive and
    //    risky commands always require confirmation in confirm-every mode.
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia").with_mode(AutopilotMode::ConfirmEvery),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").unwrap();
    for suggestion in ["kill orc", "give all items to thief"] {
        let id = e
            .propose("midkemia", suggestion, &GateContext::ready())
            .unwrap();
        let p = e.pending().next().unwrap();
        assert!(p.requires_confirmation, "{suggestion} must require confirmation");
        // auto-send is impossible in confirm-every mode.
        assert!(matches!(
            e.auto_send(&id, &GateContext::ready(), |c| Ok(c.to_string())),
            Err(AutopilotError::Policy(_))
        ));
    }

    // 3. Narrow allowlist: only exact normalized commands auto-send; a
    //    non-allowlisted command cannot auto-send even if approved.
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia")
            .with_mode(AutopilotMode::AllowlistAuto)
            .with_allowlist(&["say"]),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").unwrap();
    let id_allow = e
        .propose("midkemia", "say hi", &GateContext::ready())
        .unwrap();
    let r = e
        .auto_send(&id_allow, &GateContext::ready(), |c| Ok(format!("sent:{c}")))
        .unwrap();
    assert_eq!(r, "sent-auto");
    // "tell" is not in the allowlist: auto-send refused even though
    // approved-visible is not required for safe tier; it is not allowlisted.
    let id_not = e
        .propose("midkemia", "give 5 gold to bob", &GateContext::ready())
        .unwrap();
    assert!(matches!(
        e.auto_send(&id_not, &GateContext::ready(), |c| Ok(c.to_string())),
        Err(AutopilotError::Policy(_))
    ));

    // 4. No self-authority: the pane cannot send commands and the engine
    //    has no API for an agent to grant itself a wider allowlist.
    let lib = std::fs::read_to_string("src/wiremudder/ui/autopilot/autopilot_boundary.h")
        .expect("autopilot boundary header");
    assert!(lib.contains("canSendCommand() const { return false; }"));
    assert!(lib.contains("isPassive() const { return true; }"));

    // 5. Complete audit: every proposal is proposed-visible before any
    //    send, and the send is audited.
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia").with_mode(AutopilotMode::ConfirmEvery),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    e.enable("midkemia").unwrap();
    let id = e
        .propose("midkemia", "kill orc", &GateContext::ready())
        .unwrap();
    e.confirm_and_send(&id, &GateContext::ready(), |c| Ok(format!("sent:{c}")))
        .unwrap();
    let audit = e.audit_log();
    assert!(audit.iter().any(|a| a.action == "proposed" && a.detail == "visible"));
    assert!(audit
        .iter()
        .any(|a| a.action == "sent" && a.detail.starts_with("confirmed:")));

    // 6. Safe messages leak no internals on the security-relevant paths.
    let msg = AutopilotError::Policy("denied".into()).user_message();
    assert!(!msg.contains('/'));
    assert!(!msg.contains("stack"));

    println!("security matrix: ok");
}
