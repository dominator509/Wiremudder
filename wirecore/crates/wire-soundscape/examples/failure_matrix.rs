//! EP-026 M4 failure matrix: real controlled failures through the
//! production wire-soundscape crate.
//!
//! Required failure proofs (node contract):
//! 1. Unavailable dependency or worker.
//! 2. Timeout and cancellation.
//! 3. Malformed or oversized input.
//! 4. Duplicate or replayed request.
//! 5. Denied permission, consent, route, or policy.
//! 6. Resource or queue budget exhaustion.
//! 7. Partial side effect and compensation.
//! 8. Preserved manual gameplay and data integrity.

use wire_soundscape::{
    AssetPackEntry, SoundscapeDenial, SoundscapeEngine, SoundscapeKind, SoundscapeMode,
};

fn asset(id: &str) -> AssetPackEntry {
    AssetPackEntry {
        id: id.into(),
        license: "CC0-1.0".into(),
        provenance: "original:wiremudder:procedural".into(),
        sha256: "a".repeat(64),
        signature: Some("sig".into()),
        user_local: false,
        permissions: vec!["play".into()],
    }
}

fn base_engine() -> SoundscapeEngine {
    let mut e = SoundscapeEngine::new();
    e.register_asset(asset("amb-room")).unwrap();
    e.register_binding(SoundscapeKind::Room, "amb-room", None)
        .unwrap();
    e
}

fn main() {
    // 1. Unavailable dependency/worker: audio failure degrades to
    //    silence; text gameplay preserved.
    let mut e = base_engine();
    e.request_play("default", SoundscapeKind::Room, "amb-room", false)
        .unwrap();
    e.fail_audio();
    assert!(e.failed());
    assert_eq!(e.queue_len(), 0);
    assert_eq!(e.current(), None);
    assert_eq!(
        e.request_play("default", SoundscapeKind::Room, "amb-room", false),
        Err(SoundscapeDenial::UnavailableDependency)
    );
    assert_eq!(e.degrade_to_text(), SoundscapeMode::Disabled);
    println!("failure-1 unavailable-worker: silence-degrade ok");

    // 2. Timeout and cancellation: bounded transition overrun drops to
    //    silence; cancel works.
    let mut e2 = base_engine();
    e2.register_binding(SoundscapeKind::Weather, "amb-room", None)
        .unwrap();
    e2.request_play("default", SoundscapeKind::Room, "amb-room", false)
        .unwrap();
    e2.tick(1);
    e2.start_transition(SoundscapeKind::Weather, 100).unwrap();
    assert!(e2.cancel_transition());
    assert!(e2.transition().is_none());
    e2.start_transition(SoundscapeKind::Weather, 100).unwrap();
    e2.tick(wire_soundscape::MAX_TRANSITION_MS + 1); // overrun
    assert!(e2.transition().is_none());
    println!("failure-2 timeout-cancellation: transition bounded ok");

    // 3. Malformed or oversized input: bad hash rejected; missing
    //    binding denied.
    let mut e3 = base_engine();
    assert_eq!(
        e3.register_asset(AssetPackEntry {
            sha256: "short".into(),
            ..asset("bad-hash")
        }),
        Err(SoundscapeDenial::MalformedInput)
    );
    assert_eq!(
        e3.request_play("default", SoundscapeKind::Boss, "amb-room", false),
        Err(SoundscapeDenial::NotConfigured)
    );
    println!("failure-3 malformed-input: ok");

    // 4. Duplicate or replayed request: replay of current loop denied.
    let mut e4 = base_engine();
    e4.request_play("default", SoundscapeKind::Room, "amb-room", false)
        .unwrap();
    e4.tick(1);
    assert_eq!(
        e4.request_play("default", SoundscapeKind::Room, "amb-room", false),
        Err(SoundscapeDenial::DuplicateRequest)
    );
    assert_eq!(
        e4.register_asset(asset("amb-room")),
        Err(SoundscapeDenial::DuplicateRequest)
    );
    println!("failure-4 duplicate-replay: ok");

    // 5. Denied permission/consent/policy: disabled profile, muted,
    //    disabled binding, user-authored without author.
    let mut e5 = base_engine();
    e5.set_profile_controls("default", 70, true).unwrap();
    assert_eq!(
        e5.request_play("default", SoundscapeKind::Room, "amb-room", false),
        Err(SoundscapeDenial::Disabled)
    );
    e5.set_profile_controls("default", 0, false).unwrap();
    assert_eq!(
        e5.request_play("default", SoundscapeKind::Room, "amb-room", false),
        Err(SoundscapeDenial::ProfileMuted)
    );
    e5.set_profile_controls("default", 70, false).unwrap();
    e5.set_binding_enabled(SoundscapeKind::Room, false);
    assert_eq!(
        e5.request_play("default", SoundscapeKind::Room, "amb-room", false),
        Err(SoundscapeDenial::Disabled)
    );
    assert_eq!(
        e5.register_binding(SoundscapeKind::UserAuthored, "amb-room", None),
        Err(SoundscapeDenial::DeniedPolicy)
    );
    println!("failure-5 denied-policy: ok");

    // 6. Resource or queue budget exhaustion: queue capped; load
    //    shedding keeps the current loop or silence.
    let mut e6 = base_engine();
    e6.register_asset(asset("amb-more")).unwrap();
    e6.register_binding(SoundscapeKind::Area, "amb-more", None)
        .unwrap();
    for i in 0..(wire_soundscape::MAX_AUDIO_QUEUE + 20) {
        let kind = if i % 2 == 0 {
            SoundscapeKind::Room
        } else {
            SoundscapeKind::Area
        };
        let _ = e6.request_play("default", kind, "amb-more", false);
    }
    assert!(e6.queue_len() <= wire_soundscape::MAX_AUDIO_QUEUE);
    assert!(e6.metrics().dropped > 0);
    println!("failure-6 queue-exhaustion: load-shed ok");

    // 7. Partial side effect and compensation: transition started then
    //    cancelled leaves no half state; emergency stop clears all.
    let mut e7 = base_engine();
    e7.register_binding(SoundscapeKind::Victory, "amb-room", None)
        .unwrap();
    e7.request_play("default", SoundscapeKind::Room, "amb-room", false)
        .unwrap();
    e7.tick(1);
    e7.start_transition(SoundscapeKind::Victory, 200).unwrap();
    e7.emergency_stop();
    assert!(e7.stopped());
    assert_eq!(e7.queue_len(), 0);
    assert_eq!(e7.transition(), None);
    e7.reset();
    assert!(!e7.stopped());
    println!("failure-7 partial-effect-compensation: ok");

    // 8. Preserved manual gameplay and data integrity: after every
    //    failure the engine is still bounded, auditable, and text
    //    gameplay is untouched (no text path).
    let mut e8 = base_engine();
    for _ in 0..10 {
        e8.fail_audio();
        e8.reset();
    }
    assert!(e8.audit().len() > 0);
    assert!(!e8.can_send_command());
    e8.request_play("default", SoundscapeKind::Room, "amb-room", false)
        .unwrap();
    println!("failure-8 gameplay-preserved: ok");
    println!("failure matrix EP-026: ok");
}
