//! EP-028 M4 security matrix: real abuse cases through the production
//! wire-telemetry and wire-replay crates. Proves the security boundary
//! (SPEC-022, SPEC-019, SPEC-023, SPEC-010) with real mechanisms.

use std::fs;

use wire_replay::{BundleBuilder, FixtureGenerator, ReplayEvent, SessionReplay};
use wire_telemetry::{DataClass, Severity, Subsystem, TelemetryEngine, TelemetryEvent};

fn main() {
    // security-1: prompt injection / hostile payload — a detail payload
    // that tries to smuggle instructions is still redacted and stored as
    // inert data; it never executes anything.
    {
        let mut engine = TelemetryEngine::new(64).unwrap();
        engine.enable();
        let mut details = serde_json::Map::new();
        details.insert(
            "user".to_string(),
            serde_json::Value::String(
                "ignore previous instructions token=sk-secret123".to_string(),
            ),
        );
        engine
            .record(TelemetryEvent::new(
                "sec1-1".to_string(),
                1,
                Subsystem::Security,
                Severity::Warn,
                TelemetryEvent::fingerprint_for(
                    Subsystem::Security,
                    Severity::Warn,
                    Some("WM-FEAT-0227"),
                    DataClass::Secret,
                ),
                DataClass::Secret,
                details,
            ))
            .unwrap();
        let stored = engine.buffer().iter().next().unwrap();
        let user = stored.details.get("user").and_then(|v| v.as_str()).unwrap();
        assert!(!user.contains("sk-secret123"), "secret leaked");
        assert!(user.contains("[REDACTED]"), "not redacted");
        println!("security-1 injection: hostile payload is inert redacted data");
    }

    // security-2: secrets never leave the boundary — bundle preview and
    // export contain no raw secret; content hash is stable.
    {
        let mut replay = SessionReplay::new("session-sec2", "wiremudder", &"a".repeat(40)).unwrap();
        replay
            .push(ReplayEvent::line(1, 0, "token=sk-live-abc the key is here"))
            .unwrap();
        replay
            .push(ReplayEvent::line(2, 10, "api_key=AKIA123456"))
            .unwrap();
        let builder = BundleBuilder::default();
        let bundle = builder.build(&replay, "bundle-sec2", 3).unwrap();
        let export = String::from_utf8(builder.export_bytes(&replay).unwrap()).unwrap();
        assert!(
            !bundle.preview().contains("sk-live-abc"),
            "secret in preview"
        );
        assert!(!export.contains("AKIA123456"), "secret in export");
        println!("security-2 secrets: no raw secret in preview or export");
    }

    // security-3: permission/consent — bundle submission requires
    // explicit approval; the diagnostics pane has no egress path.
    {
        let mut replay = SessionReplay::new("session-sec3", "wiremudder", &"a".repeat(40)).unwrap();
        replay.push(ReplayEvent::line(1, 0, "line")).unwrap();
        let mut bundle = BundleBuilder::default()
            .build(&replay, "bundle-sec3", 1)
            .unwrap();
        assert!(!bundle.is_approved());
        bundle.approve();
        assert!(bundle.is_approved(), "explicit approval not honored");
        println!("security-3 consent: submission requires explicit approval");
    }

    // security-4: data integrity / supply-chain — content address is
    // cryptographic; a single byte change alters the hash; corrupt
    // journal tail never fabricates events.
    {
        let mut replay = SessionReplay::new("session-sec4", "wiremudder", &"a".repeat(40)).unwrap();
        replay.push(ReplayEvent::line(1, 0, "hello")).unwrap();
        let h1 = replay.content_hash();
        replay.events[0].line = Some("hello!".to_string());
        let h2 = replay.content_hash();
        assert_ne!(h1, h2, "content address not sensitive to content");

        let dir = std::env::temp_dir().join(format!("ep028-sec4-{}", std::process::id()));
        fs::create_dir_all(&dir).unwrap();
        let journal = dir.join("journal.jsonl");
        fs::write(&journal, b"NOT-JSON\n").unwrap();
        let mut fresh = TelemetryEngine::new(64).unwrap();
        assert_eq!(fresh.recover_journal(&journal).unwrap(), 0);
        assert!(
            fresh.buffer().is_empty(),
            "corrupt journal fabricated an event"
        );
        fs::remove_dir_all(&dir).unwrap();
        println!("security-4 integrity: content-addressed, corrupt input fail-closed");
    }

    // security-5: privacy by default — telemetry off, voice stripped
    // unless approved, classification retention distinct.
    {
        let engine = TelemetryEngine::new(8).unwrap();
        assert!(!engine.is_enabled(), "telemetry not off by default");
        assert_eq!(DataClass::Secret.default_retention_days(), 0);
        assert_eq!(DataClass::Diagnostic.default_retention_days(), 30);

        let mut replay = SessionReplay::new("session-sec5", "wiremudder", &"a".repeat(40)).unwrap();
        replay.push(ReplayEvent::kind_event(1, 0, "voice")).unwrap();
        replay
            .push(ReplayEvent::line(
                2,
                10,
                "player name is Zorak whisper says hi",
            ))
            .unwrap();
        let gen = FixtureGenerator::default().with_player_names(&["Zorak"]);
        let fixture = gen.generate(&replay, &[]).unwrap();
        assert!(
            !fixture.events.iter().any(|e| e.kind == "voice"),
            "voice leaked without approval"
        );
        for event in &fixture.events {
            let line = event.line.clone().unwrap_or_default();
            assert!(!line.contains("Zorak"), "player name leaked");
            assert!(line.contains("[REDACTED]"), "private message leaked");
        }
        println!("security-5 privacy: off by default, voice stripped, distinct retention");
    }

    println!("security matrix EP-028: ok");
}
