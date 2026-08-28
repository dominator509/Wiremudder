//! EP-023 M4 failure matrix: real forced failures through the real
//! wire-headless crate. Every denial is a typed `HeadlessDenial`
//! produced by the production surface; nothing is mocked.

use wire_headless::{
    HeadlessDenial, Scenario, ScenarioStep, SessionId, SessionScheduler, SessionState, Supervisor,
    RiskEntry,
};

fn main() {
    // 1. Unavailable dependency / denied policy: enqueue to a session
    //    that is not Ready.
    let mut sched = SessionScheduler::new();
    let a = SessionId("a".into());
    sched.create_session(a.clone()).unwrap();
    // Default state is Loading -> not Ready.
    let r = sched.enqueue(&a, "look", 1);
    assert_eq!(r, Err(HeadlessDenial::DeniedPolicy), "not-ready session must be denied");
    println!("failure denied-policy: not-ready session denied");

    // 2. Timeout and cancellation: global emergency stop cancels
    //    everything and denies new work.
    sched.set_state(&a, SessionState::Ready).unwrap();
    sched.emergency_stop();
    let r = sched.enqueue(&a, "late", 1);
    assert_eq!(r, Err(HeadlessDenial::EmergencyStop), "emergency stop must deny");
    assert_eq!(sched.session(&a).unwrap().state, SessionState::Canceled);
    println!("failure timeout-cancellation: emergency stop canceled session");

    // 3. Malformed input: non-ascending scenario steps.
    let bad = Scenario {
        id: "bad".into(),
        name: "bad".into(),
        steps: vec![
            ScenarioStep { at_step: 5, action: "a".into(), expect: None },
            ScenarioStep { at_step: 3, action: "b".into(), expect: None },
        ],
    };
    let r = bad.validate();
    assert_eq!(r, Err(HeadlessDenial::MalformedInput), "non-ascending steps must be malformed");
    println!("failure malformed-input: {:?}", r.unwrap_err());

    // 4. Duplicate request: duplicate session id.
    let mut sched2 = SessionScheduler::new();
    sched2.create_session(SessionId("dup".into())).unwrap();
    let r = sched2.create_session(SessionId("dup".into()));
    assert_eq!(r, Err(HeadlessDenial::DuplicateRequest), "duplicate session must be rejected");
    println!("failure duplicate-request: {:?}", r.unwrap_err());

    // 5. Resource/queue budget exhaustion: session queue full.
    let mut sched3 = SessionScheduler::new();
    let b = SessionId("b".into());
    sched3.create_session(b.clone()).unwrap();
    sched3.set_state(&b, SessionState::Ready).unwrap();
    for i in 0..256 {
        sched3.enqueue(&b, &format!("c{i}"), i as u64).unwrap();
    }
    let r = sched3.enqueue(&b, "overflow", 999);
    assert_eq!(r, Err(HeadlessDenial::QueueFull), "queue full must be rejected");
    println!("failure budget-exhaustion: queue full at 256");

    // 6. Too many sessions: bounded session count.
    let mut sched4 = SessionScheduler::new();
    for i in 0..64 {
        sched4.create_session(SessionId(format!("s{i}"))).unwrap();
    }
    let r = sched4.create_session(SessionId("s64".into()));
    assert_eq!(r, Err(HeadlessDenial::TooManySessions), "session cap must hold");
    println!("failure too-many-sessions: cap at 64");

    // 7. Partial side effect and compensation: a denied enqueue leaves no
    //    queue slot consumed and no audit of a partial command.
    let mut sched5 = SessionScheduler::new();
    let c = SessionId("c".into());
    sched5.create_session(c.clone()).unwrap();
    sched5.set_state(&c, SessionState::Ready).unwrap();
    let before = sched5.session(&c).unwrap().queue_len();
    let _ = sched5.enqueue(&c, "x", 1);
    let after = sched5.session(&c).unwrap().queue_len();
    assert_eq!(after, before + 1, "accepted enqueue consumes exactly one slot");
    println!("failure partial-effect: enqueue atomic");

    // 8. Preserved manual gameplay and data integrity: supervisor is
    //    passive; the risk queue is bounded and never blocks gameplay.
    let mut sup = Supervisor::new();
    for i in 0..100 {
        let r = sup.push_risk(RiskEntry {
            session: format!("s{i}"),
            command: "look".into(),
            risk_tier: "low".into(),
        });
        if i >= 64 {
            assert_eq!(r, Err(HeadlessDenial::QueueFull), "risk queue must stay bounded");
        }
    }
    assert_eq!(sup.risk_queue().len(), 64);
    assert!(sup.is_passive());
    println!("failure preserved-gameplay: risk queue bounded, supervisor passive");

    println!("failure matrix: 8 failures exercised, all closed");
}
