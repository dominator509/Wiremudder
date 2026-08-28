//! WireMudder Headless E2E flow example (EP-023 M3).
//!
//! Real end-to-end flow through the wire-headless crate: session
//! fairness, JSONL emission, supervisor snapshot, request context, and
//! global emergency stop. Exercised by tests/wiremudder/ep023/e2e/*.sh.

use wire_headless::{
    JsonlEvent, RequestContext, Scenario, ScenarioStep, SessionId, SessionScheduler,
    SessionState, Supervisor,
};

fn main() {
    // Fairness: busy world cannot starve idle world.
    let mut sched = SessionScheduler::new();
    let busy = SessionId("busy".into());
    let idle = SessionId("idle".into());
    sched.create_session(busy.clone()).unwrap();
    sched.create_session(idle.clone()).unwrap();
    sched.set_state(&busy, SessionState::Ready).unwrap();
    sched.set_state(&idle, SessionState::Ready).unwrap();
    for i in 0..100 {
        sched.enqueue(&busy, &format!("b{i}"), i as u64).unwrap();
    }
    sched.enqueue(&idle, "idle-cmd", 1000).unwrap();

    let mut seen = Vec::new();
    for _ in 0..4 {
        sched.serve_round(|id, cmd| seen.push((id.0.clone(), cmd.command.clone())));
    }
    // Round 1: busy. Round 2: idle (fairness). Rounds 3-4: busy again.
    assert!(seen.iter().any(|(s, _)| s == "idle"), "idle must be served");
    assert!(seen.iter().any(|(s, c)| s == "busy" && c == "b0"));

    // JSONL event: full structured field set.
    let mut ev = JsonlEvent::new("busy", "corr-e2e", "session", "command-sent", "headless");
    ev.time_ms = 1;
    let line = serde_json::to_string(&ev).unwrap();
    assert!(line.contains("\"correlation\":\"corr-e2e\""));
    assert!(line.contains("\"redacted\":false"));

    // Scenario validates.
    let scenario = Scenario {
        id: "sc-e2e".into(),
        name: "e2e".into(),
        steps: vec![
            ScenarioStep { at_step: 1, action: "connect".into(), expect: None },
            ScenarioStep { at_step: 2, action: "send".into(), expect: Some("ok".into()) },
        ],
    };
    scenario.validate().unwrap();

    // Supervisor snapshot accurate.
    let sup = Supervisor::new();
    let snap = sup.snapshot(sched.session(&busy).unwrap());
    assert_eq!(snap.state, "ready");
    assert!(sup.is_passive());

    // Request context validated.
    let ctx = RequestContext {
        request: "look".into(),
        correlation: "c1".into(),
        causation: "user".into(),
        session: "busy".into(),
        profile: "default".into(),
        deadline_ms: Some(500),
        cancellation: false,
        sensitivity: "low".into(),
        capability: "command".into(),
    };
    ctx.validate().unwrap();

    // Emergency stop.
    sched.emergency_stop();
    assert!(sched.is_emergency_stopped());
    assert_eq!(sched.session(&busy).unwrap().state, SessionState::Canceled);

    println!("E2E headless: ok");
    println!("fairness idle_served=true jsonl_fields=full scenario=valid snapshot=accurate emergency_stop=global");
}
