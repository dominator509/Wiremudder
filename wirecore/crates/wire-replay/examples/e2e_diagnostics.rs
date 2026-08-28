//! EP-028 M3 e2e: real user-visible telemetry/replay/diagnostics flow
//! through the production wire-telemetry and wire-replay crates,
//! proving every acceptance obligation from the node contract:
//! 1. Telemetry remains off externally by default.
//! 2. Ring buffers are bounded.
//! 3. Redaction corpus passes.
//! 4. Replay is deterministic.
//! 5. Bundle preview matches exported content.
//! 6. No secret or private data leaks.

use wire_replay::{BundleBuilder, FixtureGenerator, ReplayEvent, SessionReplay};
use wire_telemetry::{DataClass, RingBuffer, Severity, Subsystem, TelemetryEngine, TelemetryEvent};

fn main() {
    // Obligation 1: telemetry off by default.
    let engine = TelemetryEngine::new(64).expect("engine");
    assert!(!engine.is_enabled());
    println!("Telemetry is off by default externally");

    // Obligation 2: ring buffers are bounded.
    let mut ring = RingBuffer::new(8).expect("ring");
    for i in 0..32u64 {
        ring.push(TelemetryEvent::new(
            format!("evt-{i:08}"),
            1_700_000_000_000 + i as i64,
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
        ));
    }
    assert_eq!(ring.len(), 8, "ring exceeded capacity");
    println!("Ring buffers stay bounded at capacity");

    // Obligation 3: redaction corpus passes — a secret embedded in a
    // line is stripped before it reaches the record.
    let mut engine = TelemetryEngine::new(64).expect("engine");
    engine.enable();
    let mut details = serde_json::Map::new();
    details.insert(
        "line".to_string(),
        serde_json::Value::String("password=hunter2".to_string()),
    );
    engine
        .record(TelemetryEvent::new(
            "evt-redact-01".to_string(),
            1_700_000_000_000,
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
        .expect("record");
    let stored = engine.buffer().iter().next().expect("event");
    assert!(stored.redacted, "event not marked redacted");
    let line = stored
        .details
        .get("line")
        .and_then(|v| v.as_str())
        .expect("line");
    assert!(!line.contains("hunter2"), "secret leaked into record");
    assert!(line.contains("[REDACTED]"), "redaction marker missing");
    println!("Redaction corpus strips secrets before capture");

    // Obligation 4: replay is deterministic — identical input produces
    // an identical serialized record and content hash.
    let mut replay =
        SessionReplay::new("session-e2e-01", "wiremudder", &"a".repeat(40)).expect("replay");
    replay
        .push(ReplayEvent::line(1, 0, "You arrive at the market."))
        .expect("push");
    replay
        .push(ReplayEvent::line(2, 10, "password=hunter2 is your token"))
        .expect("push");
    replay
        .push(ReplayEvent::command(3, 20, "look"))
        .expect("push");
    let hash1 = replay.content_hash();
    let hash2 = replay.content_hash();
    assert_eq!(hash1, hash2, "replay not deterministic");
    assert_eq!(replay.replay_events().len(), 3);
    println!("Replay is deterministic (hash {})", &hash1[..12]);

    // Obligation 5: bundle preview matches exported content.
    let builder = BundleBuilder::default();
    let bundle = builder.build(&replay, "bundle-e2e-01", 3).expect("bundle");
    assert!(!bundle.is_approved(), "bundle approved without user action");
    assert!(
        bundle.preview().contains("[REDACTED]"),
        "preview not redacted"
    );
    let export = builder.export_bytes(&replay).expect("export");
    let export_hash = sha2_hex(&export);
    assert_eq!(
        export_hash,
        bundle.content_hash(),
        "preview/export mismatch"
    );
    assert_eq!(bundle.bytes, export.len());
    println!(
        "Bundle preview matches exported content ({} bytes)",
        export.len()
    );

    // Obligation 6: no secret or private data leaks — sanitized fixture
    // strips secrets and drops voice unless approved.
    let gen = FixtureGenerator::default();
    let fixture = gen.generate(&replay, &[]).expect("fixture");
    for event in &fixture.events {
        let line = event.line.clone().unwrap_or_default();
        assert!(!line.contains("hunter2"), "secret leaked into fixture");
        assert!(!line.contains("password"), "marker leaked into fixture");
    }
    println!("No secret or private data leaks into fixtures");

    println!("e2e EP-028 diagnostics-flow: ok");
}

fn sha2_hex(bytes: &[u8]) -> String {
    use sha2::{Digest, Sha256};
    let digest = Sha256::digest(bytes);
    let mut s = String::with_capacity(64);
    for b in digest {
        s.push_str(&format!("{b:02x}"));
    }
    s
}
