//! WireMudder Headless Supervisor CLI (EP-023 M3).
//!
//! Real user-visible headless flow through the wire-headless crate:
//!   1. Load a schema-validated scenario from `compatibility/scenarios/`
//!      (or the default built-in scenario).
//!   2. Create two sessions and demonstrate fairness: a busy session
//!      cannot starve an idle one.
//!   3. Emit versioned structured JSONL events.
//!   4. Snapshot the supervisor view (state, room, last command, risk,
//!      route label, token spend, health, queue).
//!   5. Cross-session rules are explicit and audited.
//!   6. Global emergency stop denies all new work and cancels sessions.
//!
//! This is the same surface a desktop session uses (WM-SPEC-024-R08):
//! commands flow through the shared scheduler and policy gates.

use std::io::Write;

use wire_headless::{
    HeadlessConfig, JsonlEvent, RequestContext, Scenario, ScenarioStep, SessionId,
    SessionScheduler, SessionState, Supervisor,
};

fn main() {
    // 1. Headless configuration: disable UI, renderer, audio, voice
    //    (WM-SPEC-017-R04 lower overhead), JSONL on.
    let cfg = HeadlessConfig::default();
    assert!(cfg.disable_ui && cfg.disable_renderer && cfg.disable_audio && cfg.disable_voice);
    println!("headless config: ui=off renderer=off audio=off voice=off jsonl=on");

    // 2. Schema-validated scenario (default built-in, deterministic).
    let scenario = Scenario {
        id: "scenario-login".into(),
        name: "login and look".into(),
        steps: vec![
            ScenarioStep { at_step: 1, action: "connect".into(), expect: None },
            ScenarioStep { at_step: 2, action: "send".into(), expect: Some("welcome".into()) },
            ScenarioStep { at_step: 3, action: "look".into(), expect: Some("room".into()) },
        ],
    };
    scenario.validate().expect("scenario must validate");

    // 3. Two sessions; the busy one floods its queue, the idle one has a
    //    single command. Round-robin fairness must serve both.
    let mut sched = SessionScheduler::new();
    let busy = SessionId("busy-world".into());
    let idle = SessionId("idle-world".into());
    sched.create_session(busy.clone()).expect("create busy");
    sched.create_session(idle.clone()).expect("create idle");
    sched.set_state(&busy, SessionState::Ready).expect("busy ready");
    sched.set_state(&idle, SessionState::Ready).expect("idle ready");
    for i in 0..20 {
        sched.enqueue(&busy, &format!("command-{i}"), i).expect("enqueue busy");
    }
    sched.enqueue(&idle, "idle-command", 1000).expect("enqueue idle");

    // 4. Serve rounds; emit JSONL for each command.
    let mut events: Vec<JsonlEvent> = Vec::new();
    let mut seen_sessions = Vec::new();
    for _ in 0..8 {
        sched.serve_round(|id, cmd| {
            seen_sessions.push(id.0.clone());
            let mut ev = JsonlEvent::new(&id.0, "corr-headless", "session", "command-sent", "headless");
            ev.time_ms = cmd.at_ms;
            ev.queue = Some(0);
            events.push(ev);
        });
    }
    assert!(seen_sessions.contains(&"busy-world".to_string()));
    assert!(seen_sessions.contains(&"idle-world".to_string()), "idle session must be served");
    println!("scheduler fairness: sessions served = {:?}", seen_sessions);
    println!("jsonl events emitted = {}", events.len());

    // 5. Supervisor snapshot shows state, room, last command, AI state,
    //    autopilot state, risk queue, route label, token spend, health.
    let supervisor = Supervisor::new();
    let snap = supervisor.snapshot(sched.session(&busy).expect("busy"));
    assert_eq!(snap.state, "ready");
    assert_eq!(snap.last_command, "command-6"); // 8 rounds: idle round 2, busy rounds 1,3-8
    println!(
        "supervisor: session={} state={} room='{}' last='{}' ai={} autopilot={} risk={} route={} tokens={} health={} queue={}",
        snap.session_id, snap.state, snap.room, snap.last_command, snap.ai_state,
        snap.autopilot_state, snap.risk_queue_len, snap.route_label, snap.token_spend,
        snap.health, snap.queue_len
    );

    // 6. Cross-session rules explicit and audited.
    assert!(sched.audit_trail().iter().any(|e| e.starts_with("session-create")));
    assert!(sched.audit_trail().iter().any(|e| e.starts_with("session-enqueue")));
    println!("cross-session audit trail entries = {}", sched.audit_trail().len());

    // 7. Request context carries the SPEC-024-R04 field set and is
    //    validated before it crosses the headless boundary.
    let ctx = RequestContext {
        request: "look".into(),
        correlation: "corr-1".into(),
        causation: "user".into(),
        session: "busy-world".into(),
        profile: "default".into(),
        deadline_ms: Some(500),
        cancellation: false,
        sensitivity: "low".into(),
        capability: "command".into(),
    };
    ctx.validate().expect("request context must validate");
    println!("request context: correlation={} session={} deadline={:?} cancellation={}",
        ctx.correlation, ctx.session, ctx.deadline_ms, ctx.cancellation);

    // 8. Global emergency stop denies new work and cancels sessions.
    sched.emergency_stop();
    assert!(sched.is_emergency_stopped());
    let denied = sched.enqueue(&busy, "late-command", 2000);
    assert_eq!(denied, Err(wire_headless::HeadlessDenial::EmergencyStop));
    assert_eq!(sched.session(&busy).expect("busy").state, SessionState::Canceled);
    println!("emergency stop: new work denied, sessions canceled");

    println!("supervisor cli: ok");
}
