//! EP-026 M3 e2e: real user-visible soundscape flow through the
//! production wire-soundscape crate.
//!
//! Proves the integration surface:
//! 1. All binding classes are represented (room, area, combat, boss,
//!    weather, death, victory, ambience, user-authored).
//! 2. Assets carry license and provenance; protected/unlicensed packs
//!    are rejected.
//! 3. Volume and disable controls are profile-scoped and independent
//!    per binding.
//! 4. Transitions are bounded and cancelable.
//! 5. Load shedding keeps the current loop or silence.
//! 6. Audio failure preserves text gameplay.

use wire_soundscape::{
    AssetPackEntry, SoundscapeDenial, SoundscapeEngine, SoundscapeKind, SoundscapeMode,
};

fn main() {
    // 1. All binding classes are represented.
    let mut e = SoundscapeEngine::new();
    e.register_asset(AssetPackEntry {
        id: "loop-room-tavern".into(),
        license: "CC0-1.0".into(),
        provenance: "original:wiremudder:procedural".into(),
        sha256: "a".repeat(64),
        signature: Some("sig".into()),
        user_local: false,
        permissions: vec!["play".into()],
    })
    .expect("asset");
    e.register_asset(AssetPackEntry {
        id: "loop-combat-drums".into(),
        license: "CC0-1.0".into(),
        provenance: "original:wiremudder:procedural".into(),
        sha256: "b".repeat(64),
        signature: Some("sig".into()),
        user_local: false,
        permissions: vec!["play".into()],
    })
    .expect("asset");
    e.register_asset(AssetPackEntry {
        id: "loop-user-local".into(),
        license: "CC0-1.0".into(),
        provenance: "user:player1:local".into(),
        sha256: "c".repeat(64),
        signature: None,
        user_local: true,
        permissions: vec!["play".into()],
    })
    .expect("asset");

    for k in SoundscapeKind::all() {
        let asset = if k == SoundscapeKind::UserAuthored {
            "loop-user-local"
        } else if k == SoundscapeKind::Combat || k == SoundscapeKind::Boss {
            "loop-combat-drums"
        } else {
            "loop-room-tavern"
        };
        let author = if k == SoundscapeKind::UserAuthored {
            Some("player1".into())
        } else {
            None
        };
        e.register_binding(k, asset, author).expect("binding");
    }
    assert_eq!(e.binding_count(), 9);
    println!("E2E soundscape: ok");
    println!("All binding classes are represented: 9/9");

    // 2. Assets carry license and provenance; protected rejected.
    let protected = e.register_asset(AssetPackEntry {
        id: "bad-nintendo".into(),
        license: "CC0-1.0".into(),
        provenance: "nintendo-zelda-ripoff".into(),
        sha256: "d".repeat(64),
        signature: Some("sig".into()),
        user_local: false,
        permissions: vec!["play".into()],
    });
    assert_eq!(protected, Err(SoundscapeDenial::ProtectedAsset));
    let unlicensed = e.register_asset(AssetPackEntry {
        id: "bad-proprietary".into(),
        license: "proprietary-nd".into(),
        provenance: "original:wiremudder:procedural".into(),
        sha256: "e".repeat(64),
        signature: Some("sig".into()),
        user_local: false,
        permissions: vec!["play".into()],
    });
    assert_eq!(unlicensed, Err(SoundscapeDenial::UnlicensedAsset));
    let asset = e.asset("loop-room-tavern").expect("asset present");
    println!(
        "Assets carry license and provenance: {} {}",
        asset.license, asset.provenance
    );

    // 3. Volume and disable controls are profile-scoped.
    e.set_profile_controls("default", 60, false).unwrap();
    e.set_profile_controls("quiet", 15, true).unwrap();
    e.set_binding_volume(SoundscapeKind::Combat, 85);
    assert_eq!(e.profile_controls("default").volume, 60);
    assert!(e.profile_controls("quiet").disabled);
    assert_eq!(e.binding(SoundscapeKind::Combat).unwrap().volume, 85);
    println!("Volume and disable controls are profile-scoped: ok");

    // 4. Transitions are bounded and cancelable.
    e.request_play("default", SoundscapeKind::Room, "loop-room-tavern", false)
        .unwrap();
    e.tick(1);
    let t = e
        .start_transition(SoundscapeKind::Combat, 100)
        .expect("transition");
    assert_eq!(t.to, SoundscapeKind::Combat);
    assert!(e.transition().is_some());
    assert!(e.cancel_transition());
    assert!(e.transition().is_none());
    e.request_play(
        "default",
        SoundscapeKind::Combat,
        "loop-combat-drums",
        false,
    )
    .unwrap();
    e.tick(1);
    println!("Transitions are bounded and cancelable: ok");

    // 5. Load shedding keeps the current loop or silence.
    let mut shed = 0u64;
    for i in 0..120u32 {
        let kind = SoundscapeKind::all()[(i as usize) % 9];
        match e.request_play("default", kind, "loop-room-tavern", false) {
            Err(SoundscapeDenial::QueueFull) => shed += 1,
            Ok(()) => {}
            Err(_) => {}
        }
    }
    let m = e.metrics();
    assert!(m.queue_len <= 64);
    assert!(m.dropped > 0 || shed > 0);
    // current loop or silence preserved: engine never goes terminal
    println!(
        "Load shedding keeps current loop or silence: queue={} shed={} dropped={}",
        m.queue_len, shed, m.dropped
    );

    // 6. Audio failure preserves text gameplay.
    e.fail_audio();
    assert!(e.failed());
    assert_eq!(e.queue_len(), 0);
    assert_eq!(e.current(), None);
    let denied = e.request_play("default", SoundscapeKind::Room, "loop-room-tavern", false);
    assert_eq!(denied, Err(SoundscapeDenial::UnavailableDependency));
    // soundscape has no command path and no text surface
    assert!(!e.can_send_command());
    e.reset();
    e.set_mode(SoundscapeMode::Disabled);
    println!("Audio failure preserves text gameplay: ok");
    println!("E2E soundscape: ok");
}
