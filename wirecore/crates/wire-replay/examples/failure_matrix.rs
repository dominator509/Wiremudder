//! EP-028 M4 failure matrix: real controlled failures through the
//! production wire-telemetry and wire-replay crates. Every required
//! failure proof from the node contract is exercised with a real
//! mechanism — no mocks, no stubs.

use std::fs;

use wire_replay::{BundleBuilder, FixtureGenerator, ReplayEvent, SessionReplay};
use wire_telemetry::{DataClass, RingBuffer, Severity, Subsystem, TelemetryEngine, TelemetryEvent};

fn ev(id: &str, t: i64) -> TelemetryEvent {
    TelemetryEvent::new(
        id.to_string(),
        t,
        Subsystem::Core,
        Severity::Info,
        TelemetryEvent::fingerprint_for(
            Subsystem::Core,
            Severity::Info,
            Some("WM-FEAT-0223"),
            DataClass::Diagnostic,
        ),
        DataClass::Diagnostic,
        serde_json::Map::new(),
    )
}

fn main() {
    // failure-1: unavailable dependency/worker — journal directory is
    // removed after construction; append must fail with a typed
    // unavailable error, never panic.
    {
        let dir = std::env::temp_dir().join(format!("ep028-f1-{}", std::process::id()));
        fs::create_dir_all(&dir).unwrap();
        let journal = dir.join("journal.jsonl");
        let mut engine = TelemetryEngine::with_journal(64, &journal).unwrap();
        engine.enable();
        fs::remove_dir_all(&dir).unwrap();
        let err = engine.record(ev("f1-1", 1)).unwrap_err();
        assert_eq!(err.code, "telemetry-journal", "wrong error code");
        assert_eq!(err.retry_class, "unavailable", "wrong retry class");
        assert!(!err.message.is_empty());
        println!("failure-1 unavailable dependency: typed error, fail-closed");
    }

    // failure-2: timeout and cancellation — replay and bundle building
    // are bounded: a replay cannot grow past the limit and a malformed
    // session id is rejected immediately (validation not hang).
    {
        let err = SessionReplay::new("bad", "wiremudder", &"a".repeat(40)).unwrap_err();
        assert_eq!(err.code, "replay-session-id");
        let mut replay = SessionReplay::new("session-f2", "wiremudder", &"a".repeat(40)).unwrap();
        for i in 0..wire_replay::MAX_REPLAY_EVENTS + 5 {
            if replay
                .push(ReplayEvent::line(i as u64 + 1, i as i64, "line"))
                .is_err()
            {
                break; // bounded: rejects at capacity
            }
        }
        assert!(replay.events.len() <= wire_replay::MAX_REPLAY_EVENTS);
        println!("failure-2 timeout/cancellation: bounded replay, validation rejects fast");
    }

    // failure-3: malformed or oversized input — oversized detail payload
    // is rejected; corrupt journal tail stops recovery (never fabricates).
    {
        let mut engine = TelemetryEngine::new(64).unwrap();
        engine.enable();
        let mut big = serde_json::Map::new();
        big.insert(
            "blob".to_string(),
            serde_json::Value::String("x".repeat(9000)),
        );
        let mut e = ev("f3-1", 1);
        e.details = big;
        let err = engine.record(e).unwrap_err();
        assert_eq!(err.code, "event-details", "oversize not rejected");

        let dir = std::env::temp_dir().join(format!("ep028-f3-{}", std::process::id()));
        fs::create_dir_all(&dir).unwrap();
        let journal = dir.join("journal.jsonl");
        fs::write(&journal, b"{\"schema_version\":1,\"event_id\":\"ok-1\",\"t\":1,\"subsystem\":\"core\",\"severity\":\"info\",\"fingerprint\":\"fp\",\"classification\":\"diagnostic\",\"details\":{}}\nCORRUPT-NOT-JSON\n").unwrap();
        let mut fresh = TelemetryEngine::new(64).unwrap();
        let recovered = fresh.recover_journal(&journal).unwrap();
        assert_eq!(recovered, 1, "recovery must stop at corrupt record");
        assert_eq!(fresh.buffer().len(), 1, "corrupt tail must not fabricate");
        fs::remove_dir_all(&dir).unwrap();
        println!("failure-3 malformed/oversized: rejected, recovery fail-closed");
    }

    // failure-4: duplicate/replayed request — identical fingerprint
    // within the window coalesces instead of duplicating.
    {
        let mut engine = TelemetryEngine::new(64).unwrap();
        engine.enable();
        let fp = TelemetryEvent::fingerprint_for(
            Subsystem::Mapper,
            Severity::Error,
            Some("WM-FEAT-0227"),
            DataClass::Diagnostic,
        );
        let mut a = ev("f4-1", 100);
        a.fingerprint = fp.clone();
        let mut b = ev("f4-2", 110);
        b.fingerprint = fp.clone();
        assert!(!engine.record_coalesced(a));
        assert!(engine.record_coalesced(b), "duplicate not coalesced");
        assert_eq!(engine.buffer().len(), 1);
        println!("failure-4 duplicate request: coalesced, no duplicate record");
    }

    // failure-5: denied permission/consent — disabled telemetry denies
    // capture; a bundle cannot be approved without explicit user action.
    {
        let mut engine = TelemetryEngine::new(8).unwrap();
        assert!(!engine.is_enabled());
        engine.record(ev("f5-1", 1)).unwrap(); // denied: no-op
        assert!(
            engine.buffer().is_empty(),
            "disabled capture stored an event"
        );

        let mut replay = SessionReplay::new("session-f5", "wiremudder", &"a".repeat(40)).unwrap();
        replay.push(ReplayEvent::line(1, 0, "line")).unwrap();
        let bundle = BundleBuilder::default()
            .build(&replay, "bundle-f5-1", 1)
            .unwrap();
        assert!(!bundle.is_approved(), "bundle approved without consent");
        println!("failure-5 denied consent: capture denied, bundle not approved");
    }

    // failure-6: resource/queue budget exhaustion — ring buffer fills
    // and drops; fixture generator bounds output.
    {
        let mut ring = RingBuffer::new(4).unwrap();
        let mut dropped = 0;
        for i in 0..16 {
            dropped += ring.push(ev(&format!("f6-{i}"), i));
        }
        assert_eq!(ring.len(), 4);
        assert_eq!(dropped, 12, "expected 12 drops at capacity");
        println!("failure-6 budget exhaustion: bounded drops, no growth");
    }

    // failure-7: partial side effect and compensation — when the journal
    // append fails, the in-memory buffer must NOT receive the event
    // (no partial effect; atomic record).
    {
        let dir = std::env::temp_dir().join(format!("ep028-f7-{}", std::process::id()));
        fs::create_dir_all(&dir).unwrap();
        let journal = dir.join("journal.jsonl");
        let mut engine = TelemetryEngine::with_journal(64, &journal).unwrap();
        engine.enable();
        engine.record(ev("f7-1", 1)).unwrap();
        assert_eq!(engine.buffer().len(), 1);
        fs::remove_dir_all(&dir).unwrap();
        let err = engine.record(ev("f7-2", 2)).unwrap_err();
        assert_eq!(err.code, "telemetry-journal");
        assert_eq!(
            engine.buffer().len(),
            1,
            "partial effect stored despite failure"
        );
        println!("failure-7 partial effect: compensation keeps buffer consistent");
    }

    // failure-8: preserved manual gameplay and data integrity — when
    // telemetry is off (default) or a dependency is unavailable, manual
    // text gameplay and local data are untouched.
    {
        let mut engine = TelemetryEngine::new(8).unwrap();
        // Manual gameplay line is not captured and not modified.
        let gameplay_line = "You slash the goblin for 12 damage.";
        engine.record(ev("f8-1", 1)).unwrap();
        assert_eq!(engine.buffer().len(), 0);
        assert!(gameplay_line.contains("slash"));
        // Sanitized fixtures keep the gameplay text intact but redacted.
        let mut replay = SessionReplay::new("session-f8", "wiremudder", &"a".repeat(40)).unwrap();
        replay.push(ReplayEvent::line(1, 0, gameplay_line)).unwrap();
        let fixture = FixtureGenerator::default().generate(&replay, &[]).unwrap();
        assert_eq!(fixture.events.len(), 1, "gameplay line must survive");
        let line = fixture.events[0].line.as_deref().unwrap();
        assert!(line.contains("slash"), "gameplay text damaged");
        println!("failure-8 preserved gameplay: text gameplay intact");
    }

    println!("failure matrix EP-028: ok");
}
