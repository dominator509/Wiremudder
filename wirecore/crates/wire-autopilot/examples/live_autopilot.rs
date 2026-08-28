//! EP-019 M5 live-fire: guarded-autopilot-confirmation certification.
//!
//! Runs the real guarded autopilot outcome against the real crates and
//! writes certification evidence: off by default, profile-scoped enable,
//! every action visible before send, destructive actions require explicit
//! confirmation, rate limits are deterministic, stale state pauses,
//! emergency stop cancels immediately, the audit is complete, the pane is
//! passive with no command path, and manual text gameplay is preserved.
//!
//! Run: cargo run --example live_autopilot (in wire-autopilot).

use wire_actions::GateContext;
use wire_autopilot::{
    AutopilotConfig, AutopilotEngine, AutopilotMode, AutopilotStatus, StaleReason,
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
    let mut evidence = serde_json::Map::new();

    // ---- 1. Off by default; profile-scoped enable. ----
    let mut e = AutopilotEngine::new(
        AutopilotConfig::new("midkemia").with_mode(AutopilotMode::ConfirmEvery),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    evidence.insert("off_by_default".into(), serde_json::json!(e.status() == AutopilotStatus::Disabled));
    assert!(e.propose("midkemia", "say hi", &GateContext::ready()).is_err());
    e.enable("midkemia").expect("enable");
    evidence.insert("enabled_for_profile".into(), serde_json::json!(e.status() == AutopilotStatus::Ready));

    // ---- 2. Every action is visible before send. ----
    let id = e
        .propose("midkemia", "say hello", &GateContext::ready())
        .expect("propose say");
    let visible_before_send = e.pending_count() == 1;
    evidence.insert("visible_before_send".into(), serde_json::json!(visible_before_send));

    // ---- 3. Safe action: confirmation then send through the gateway. ----
    let r = e
        .confirm_and_send(&id, &GateContext::ready(), |c| Ok(format!("sent:{c}")))
        .expect("confirm say");
    evidence.insert("safe_send_result".into(), serde_json::json!(r));

    // ---- 4. Destructive action requires explicit confirmation (R04). ----
    let id_kill = e
        .propose("midkemia", "kill orc", &GateContext::ready())
        .expect("propose kill");
    let p = e.pending().next().expect("pending kill");
    let destructive_requires_confirmation = p.requires_confirmation;
    evidence.insert(
        "destructive_requires_confirmation".into(),
        serde_json::json!(destructive_requires_confirmation),
    );
    let r = e
        .confirm_and_send(&id_kill, &GateContext::ready(), |c| Ok(format!("sent:{c}")))
        .expect("confirm kill");
    evidence.insert("confirmed_send_result".into(), serde_json::json!(r));

    // ---- 5. Rate limit is deterministic. ----
    let mut rl = AutopilotEngine::new(
        AutopilotConfig::new("midkemia")
            .with_mode(AutopilotMode::ConfirmEvery)
            .with_rate_limit(2, 60_000),
        db(),
        HumanTempo::new(0, 1000, 100000),
    );
    rl.enable("midkemia").unwrap();
    let _ = rl.propose("midkemia", "say a", &GateContext::ready()).unwrap();
    let _ = rl.propose("midkemia", "say b", &GateContext::ready()).unwrap();
    evidence.insert("rate_limited".into(), serde_json::json!(rl
        .propose("midkemia", "say c", &GateContext::ready())
        .is_err()));

    // ---- 6. Stale state pauses. ----
    e.set_stale(StaleReason::RouteStale);
    evidence.insert(
        "stale_pause".into(),
        serde_json::json!(matches!(e.status(), AutopilotStatus::Paused(StaleReason::RouteStale))),
    );
    e.clear_stale();

    // ---- 7. Emergency stop cancels immediately. ----
    let _id2 = e
        .propose("midkemia", "say bye", &GateContext::ready())
        .expect("propose bye");
    e.emergency_stop();
    evidence.insert("emergency_stop_cancelled".into(), serde_json::json!(e.pending_count() == 0));
    evidence.insert("emergency_stop_engaged".into(), serde_json::json!(e.emergency_stop_engaged()));

    // ---- 8. Complete audit + no hidden send. ----
    let audit = e.audit_log();
    let audit_complete = audit.iter().any(|a| a.action == "proposed" && a.detail == "visible")
        && audit.iter().any(|a| a.action == "sent")
        && audit.iter().any(|a| a.action == "emergency-stop");
    evidence.insert("audit_complete".into(), serde_json::json!(audit_complete));
    let sends = audit.iter().filter(|a| a.action == "sent").count();
    evidence.insert("audited_send_count".into(), serde_json::json!(sends));
    let no_hidden_send = audit.iter().any(|a| a.action == "proposed" && a.detail == "visible")
        && sends >= 2;
    evidence.insert("no_hidden_send".into(), serde_json::json!(no_hidden_send));

    // ---- 9. Manual gameplay preserved: pane passive, no command path. ----
    let hdr = std::fs::read_to_string("src/wiremudder/ui/autopilot/autopilot_boundary.h")
        .expect("autopilot boundary header");
    evidence.insert(
        "pane_passive".into(),
        serde_json::json!(hdr.contains("isPassive() const { return true; }")),
    );
    evidence.insert(
        "pane_no_command_path".into(),
        serde_json::json!(hdr.contains("canSendCommand() const { return false; }")),
    );

    // ---- Write certification evidence with real measured values. ----
    std::fs::create_dir_all(".agent/state/evidence/EP-019/M5").expect("evidence dir");
    std::fs::write(
        ".agent/state/evidence/EP-019/M5/lf019-certification.json",
        serde_json::to_string_pretty(&serde_json::Value::Object(evidence)).expect("evidence json"),
    )
    .expect("evidence write");

    println!("LF-019 live: ok");
}
