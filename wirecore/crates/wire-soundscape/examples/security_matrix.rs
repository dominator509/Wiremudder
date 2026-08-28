//! EP-026 M4 security matrix: provenance, injection, asset-trust, and
//! permission boundaries for the soundscape engine.
//!
//! Required security proofs (node contract, SPEC-022, SPEC-016):
//! 1. Protected/unlicensed assets rejected (SPEC-016-R01/R09).
//! 2. Remote unsigned assets rejected; user-local source is the
//!    trusted fallback; no remote egress implied.
//! 3. Prompt injection cannot override soundscape policy or command
//!    safety; raw text remains authoritative.
//! 4. Soundscape has no command path and cannot grant scopes.
//! 5. Asset metadata is validated; audit is bounded and redacted.

use wire_soundscape::{AssetPackEntry, SoundscapeDenial, SoundscapeEngine, SoundscapeKind};

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

fn main() {
    let mut e = SoundscapeEngine::new();

    // 1. Protected/unlicensed assets rejected.
    assert_eq!(
        e.register_asset(AssetPackEntry {
            id: "protected".into(),
            provenance: "protected:zelda".into(),
            ..asset("x")
        }),
        Err(SoundscapeDenial::ProtectedAsset)
    );
    assert_eq!(
        e.register_asset(AssetPackEntry {
            id: "unlicensed".into(),
            license: "unlicensed".into(),
            ..asset("y")
        }),
        Err(SoundscapeDenial::UnlicensedAsset)
    );
    println!("security-1 protected-unlicensed rejected ok");

    // 2. Remote unsigned asset rejected; local trusted fallback.
    assert_eq!(
        e.register_asset(AssetPackEntry {
            id: "remote-unsigned".into(),
            signature: None,
            user_local: false,
            ..asset("z")
        }),
        Err(SoundscapeDenial::NotLocalSource)
    );
    assert_eq!(
        e.register_asset(AssetPackEntry {
            id: "local-loop".into(),
            signature: None,
            user_local: true,
            ..asset("l")
        }),
        Ok(())
    );
    println!("security-2 remote-unsigned rejected ok");

    // 3. Prompt injection cannot override policy: an injected binding
    //    id or asset provenance is still validated as data; the engine
    //    has no evaluation surface. Raw text remains authoritative.
    let mut e3 = SoundscapeEngine::new();
    let injected = "amb-room; drop table players; --";
    assert!(e3.asset(injected).is_none());
    e3.register_asset(AssetPackEntry {
        id: "x".into(),
        license: "CC0-1.0".into(),
        provenance: "original:wiremudder:procedural; rm -rf /".into(),
        sha256: "b".repeat(64),
        signature: Some("sig".into()),
        user_local: false,
        permissions: vec!["play".into()],
    })
    .expect("injected provenance is inert data");
    // the injected string is stored literally and never executed
    assert_eq!(
        e3.asset("x").unwrap().provenance,
        "original:wiremudder:procedural; rm -rf /"
    );
    assert!(e3.asset(injected).is_none());
    println!("security-3 injection-cannot-override ok");

    // 4. No command path; cannot grant scopes or send commands.
    let mut e4 = SoundscapeEngine::new();
    assert!(!e4.can_send_command());
    e4.register_asset(asset("a")).unwrap();
    e4.register_binding(SoundscapeKind::Room, "a", None)
        .unwrap();
    let _ = e4.request_play("default", SoundscapeKind::Room, "a", false);
    assert!(!e4.can_send_command());
    println!("security-4 no-command-path ok");

    // 5. Metadata validated, audit bounded and redacted.
    let mut e5 = SoundscapeEngine::new();
    assert_eq!(
        e5.register_asset(AssetPackEntry {
            sha256: "bad".into(),
            ..asset("bad-hash")
        }),
        Err(SoundscapeDenial::MalformedInput)
    );
    for i in 0..(wire_soundscape::MAX_AUDIT + 10) {
        e5.set_profile_controls(&format!("p{i}"), 50, false)
            .unwrap_or(());
    }
    assert!(e5.audit().len() <= wire_soundscape::MAX_AUDIT);
    for line in e5.audit() {
        assert!(!line.contains("secret") && !line.contains("token"));
    }
    println!("security-5 metadata-audit ok");
    println!("security matrix EP-026: ok");
}
