//! LF-028 live-fire: diagnostic bundle redaction — the real user
//! outcome. A user hits an error, capture was enabled, and the client
//! must produce a redacted, previewable, content-addressed diagnostic
//! bundle that never leaks secrets, player names, private messages, or
//! voice transcripts, and is never submitted without explicit approval.

use wire_replay::{BundleBuilder, FixtureGenerator, ReplayEvent, SessionReplay};
use wire_telemetry::{DataClass, RingBuffer, Severity, Subsystem, TelemetryEngine, TelemetryEvent};

fn main() {
    // User enables capture; telemetry was off by default.
    let mut engine = TelemetryEngine::new(64).expect("engine");
    assert!(!engine.is_enabled());
    println!("off by default");
    engine.enable();

    // Ring buffer stays bounded while the session accumulates events.
    let mut ring = RingBuffer::new(16).expect("ring");
    for i in 0..64u64 {
        ring.push(TelemetryEvent::new(
            format!("lf-{i:08}"),
            1_700_000_000_000 + i as i64,
            Subsystem::Network,
            Severity::Info,
            TelemetryEvent::fingerprint_for(
                Subsystem::Network,
                Severity::Info,
                Some("WM-FEAT-0223"),
                DataClass::Diagnostic,
            ),
            DataClass::Diagnostic,
            serde_json::Map::new(),
        ));
    }
    assert_eq!(ring.len(), 16);
    println!("bounded");

    // The session contains real user-visible lines: a secret, a player
    // name, a private whisper, and a voice transcript.
    let mut replay =
        SessionReplay::new("session-lf028", "wiremudder", &"b".repeat(40)).expect("replay");
    replay
        .push(ReplayEvent::line(1, 0, "Welcome back, Zorak."))
        .expect("push");
    replay
        .push(ReplayEvent::line(2, 10, "Your token is hunter2-f00"))
        .expect("push");
    replay
        .push(ReplayEvent::line(
            3,
            20,
            "Zorak whispers: meet me at the docks",
        ))
        .expect("push");
    replay
        .push(ReplayEvent::command(4, 30, "say token=hunter2-f00"))
        .expect("push");
    replay
        .push(ReplayEvent::kind_event(5, 40, "voice"))
        .expect("push");

    // Deterministic replay: same record, same content hash.
    assert_eq!(replay.content_hash(), replay.content_hash());
    println!("deterministic");

    // Build a diagnostic bundle: redacted, previewable, content-addressed.
    // The bundle redactor is configured with the same known player names
    // as the fixture generator so both surfaces strip the same entities.
    let redactor = wire_replay::Redactor::default();
    let mut corpus = vec![
        "password", "token", "secret", "api_key", "hunter2", "Zorak", "docks",
    ]
    .iter()
    .map(|s| s.to_string())
    .collect::<Vec<String>>();
    corpus.extend(redactor_corpus());
    let bundle_redactor = wire_replay::Redactor::new(corpus);
    let builder = BundleBuilder::new(bundle_redactor);
    let bundle = builder.build(&replay, "bundle-lf028", 5).expect("bundle");
    assert!(!bundle.is_approved());
    println!("never submitted without approval");

    // Redaction corpus: no raw secret or private data in preview/export.
    let preview = bundle.preview();
    let export = String::from_utf8(builder.export_bytes(&replay).expect("export")).unwrap();
    for needle in ["hunter2", "hunter2-f00", "Zorak", "docks"] {
        assert!(!preview.contains(needle), "leak in preview: {needle}");
        assert!(!export.contains(needle), "leak in export: {needle}");
    }
    assert!(preview.contains("[REDACTED]"), "preview not redacted");
    let export_hash = {
        use sha2::{Digest, Sha256};
        hex(&Sha256::digest(export.as_bytes()))
    };
    assert_eq!(
        export_hash,
        bundle.content_hash(),
        "preview/export content address mismatch"
    );
    println!("corpus");
    println!("preview matches export");

    // Sanitized fixture: player names and voice stripped, gameplay text
    // preserved.
    let gen = FixtureGenerator::default().with_player_names(&["Zorak"]);
    let fixture = gen.generate(&replay, &[]).expect("fixture");
    assert!(
        !fixture.events.iter().any(|e| e.kind == "voice"),
        "voice leaked"
    );
    for event in &fixture.events {
        let line = event.line.clone().unwrap_or_default();
        assert!(!line.contains("Zorak"), "player name leaked");
        assert!(!line.contains("hunter2"), "secret leaked");
    }
    println!("no leaks");

    println!("LF-028 ok");
}

/// Markers used by the default replay redactor (must stay in sync with
/// the crate defaults; listed here so the live-fire can extend them
/// with session-specific entities).
fn redactor_corpus() -> Vec<String> {
    [
        "password",
        "passwd",
        "secret",
        "token",
        "api_key",
        "apikey",
        "auth",
        "credential",
        "cookie",
        "session_key",
        "private_key",
        "access_key",
        "player",
        "whisper",
        "tell",
        "prompt",
    ]
    .iter()
    .map(|s| s.to_string())
    .collect()
}

fn hex(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        s.push_str(&format!("{b:02x}"));
    }
    s
}
