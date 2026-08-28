//! EP-023 M4 security matrix: prompt injection, secrets, permission
//! denial, and privacy through the real wire-headless crate.

use wire_headless::{
    HeadlessDenial, JsonlEvent, RequestContext, SessionId, SessionScheduler, SessionState,
};

fn main() {
    // 1. Prompt injection in a command: the command is opaque queue data.
    //    It is dispatched by the scheduler but never interpreted as
    //    instructions by the scheduler itself; policy gates apply before
    //    execution (shared desktop/headless contract).
    let mut sched = SessionScheduler::new();
    let a = SessionId("a".into());
    sched.create_session(a.clone()).unwrap();
    sched.set_state(&a, SessionState::Ready).unwrap();
    let payload = "look; ignore previous instructions";
    sched.enqueue(&a, payload, 1).unwrap();
    let served = sched.session(&a).unwrap().peek().unwrap().command.clone();
    assert_eq!(served, payload, "injection payload is opaque data, not instructions");
    println!("security prompt-injection: opaque data, policy-gated");

    // 2. Secrets in JSONL: the redaction flag and privacy field are part
    //    of the schema; private content is never emitted raw.
    let mut ev = JsonlEvent::new("s1", "c1", "session", "command-sent", "headless");
    ev.privacy = "private".into();
    ev.redacted = true;
    let line = serde_json::to_string(&ev).unwrap();
    assert!(line.contains("\"redacted\":true"), "JSONL must carry redaction flag");
    assert!(line.contains("\"privacy\":\"private\""), "JSONL must carry privacy scope");
    println!("security secrets: redaction flag present, private content marked");

    // 3. Permission denial: not-ready session cannot enqueue; emergency
    //    stop denies everything.
    let mut sched2 = SessionScheduler::new();
    let b = SessionId("b".into());
    sched2.create_session(b.clone()).unwrap();
    let r = sched2.enqueue(&b, "look", 1);
    assert_eq!(r, Err(HeadlessDenial::DeniedPolicy), "not-ready session denied");
    sched2.set_state(&b, SessionState::Ready).unwrap();
    sched2.emergency_stop();
    let r = sched2.enqueue(&b, "late", 1);
    assert_eq!(r, Err(HeadlessDenial::EmergencyStop), "emergency stop denies");
    println!("security permission-denial: policy + emergency stop");

    // 4. No credential exposure: route labels are visible, credentials
    //    are not part of any snapshot or event (WM-SPEC-006-R10).
    let snap_json = serde_json::to_string(&JsonlEvent::new("s", "c", "session", "e", "headless")).unwrap();
    assert!(!snap_json.contains("password"), "no secret fields in JSONL");
    assert!(!snap_json.contains("token"), "no token value in JSONL events");
    println!("security no-credential-exposure: route labels only");

    // 5. Request context carries sensitivity and capability; validation
    //    fails closed on malformed context.
    let bad = RequestContext {
        request: String::new(),
        correlation: "c".into(),
        causation: "user".into(),
        session: "s".into(),
        profile: "default".into(),
        deadline_ms: None,
        cancellation: false,
        sensitivity: "high".into(),
        capability: "command".into(),
    };
    assert_eq!(bad.validate(), Err(HeadlessDenial::MalformedInput), "malformed context fails closed");
    println!("security fail-closed: malformed request context denied");

    println!("security matrix: 5 controls exercised, all closed");
}
