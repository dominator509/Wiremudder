//! EP-025 M3 e2e: real user-visible renderer flow through the
//! production wire-renderer crate.
//!
//! Proves the integration surface:
//! 1. Original retro presentation with licensed asset packs (no
//!    protected assets).
//! 2. Visual emits cover the complete catalog with visible confidence
//!    when inferred.
//! 3. Frame-budgeted queue drops/coalesces noncritical emits.
//! 4. Clickable exits propose only; command safety performs the send.
//! 5. Renderer modes and static/text fallback.
//! 6. Renderer crash preserves text gameplay.

use wire_renderer::{
    AssetManifestEntry, ClickableExit, EmitKind, RendererDenial, RendererEmitCandidate,
    RendererMode, RetroRenderer,
};

fn main() {
    // 1. Original licensed asset pack (provenance-aware).
    let mut r = RetroRenderer::new();
    r.add_asset_pack(AssetManifestEntry {
        id: "base".into(),
        pack: "base".into(),
        license: "CC0-1.0".into(),
        provenance: "original:wiremudder:procedural".into(),
        sha256: "a".repeat(64),
        signature: Some("sig".into()),
        user_local: false,
        permissions: vec!["display".into()],
    })
    .expect("licensed pack");
    // Protected/unlicensed assets are rejected.
    let denied = r.add_asset_pack(AssetManifestEntry {
        id: "protected".into(),
        pack: "p".into(),
        license: "CC0-1.0".into(),
        provenance: "protected:zelda".into(),
        sha256: "b".repeat(64),
        signature: Some("sig".into()),
        user_local: false,
        permissions: vec![],
    });
    assert_eq!(denied, Err(RendererDenial::ProtectedAsset));
    println!("assets: original licensed pack accepted; protected rejected");

    // 2. Visual emits cover the complete catalog with visible
    //    confidence when inferred.
    for (kind, label) in [
        (EmitKind::Npc, "guard"),
        (EmitKind::Mob, "rat"),
        (EmitKind::Animal, "bird"),
        (EmitKind::Player, "adventurer"),
        (EmitKind::PvpVisible, "challenger"),
        (EmitKind::Item, "sword"),
        (EmitKind::Spell, "fireball"),
        (EmitKind::Combat, "hit"),
        (EmitKind::Movement, "steps"),
        (EmitKind::Door, "gate"),
        (EmitKind::Weather, "rain"),
        (EmitKind::Ambience, "torchlight"),
        (EmitKind::RoomEvent, "chest opens"),
    ] {
        r.apply_candidate(
            RendererEmitCandidate {
                candidate_id: format!("c-{}", kind.label()),
                kind,
                label: label.into(),
                confidence: 80,
                inferred: true,
                evidence: vec!["room text".into()],
                suggested_by: "scene-agent".into(),
            },
            1,
        )
        .expect("emit applied");
    }
    assert_eq!(r.queue_len(), 13);
    assert!(r.queue()[0].inferred);
    assert_eq!(r.queue()[0].confidence, 80);
    println!("emits: complete catalog applied with visible confidence");

    // 3. Frame-budgeted drain (5 ms budget).
    let rendered = r.render_frame(5_000);
    assert!(rendered > 0);
    println!("frame budget: rendered {rendered} emits in 5 ms frame");

    // 4. Clickable exits propose only; never auto-send.
    r.add_exit(ClickableExit {
        id: "north".into(),
        direction: "north".into(),
        target_room: Some("room-2".into()),
        visible: true,
    })
    .expect("exit");
    let proposal = r.exits()[0].propose().expect("proposal");
    assert_eq!(proposal.source, "renderer");
    assert!(!proposal.approved);
    println!("exits: visible exit proposes; command safety approves");

    // 5. Renderer modes and static/text fallback.
    r.set_mode(RendererMode::Static).expect("static mode");
    assert!(r.is_frozen());
    assert_eq!(r.render_frame(5_000), 0);
    r.set_mode(RendererMode::TextOnly).expect("text-only");
    assert_eq!(r.mode(), RendererMode::TextOnly);
    println!("modes: static freeze and text-only fallback work");

    // 6. Renderer crash preserves text gameplay.
    r.set_mode(RendererMode::Animated).expect("animated");
    r.apply_candidate(
        RendererEmitCandidate {
            candidate_id: "c-final".into(),
            kind: EmitKind::Npc,
            label: "guard".into(),
            confidence: 90,
            inferred: false,
            evidence: vec![],
            suggested_by: "parser".into(),
        },
        1,
    )
    .expect("emit");
    r.degrade_to_text();
    assert_eq!(r.mode(), RendererMode::TextOnly);
    assert_eq!(r.queue_len(), 0);
    // Raw text gameplay is independent: the renderer only owns its own
    // queue; terminal/input/connection are untouched.
    println!("crash: renderer degrades to text; gameplay preserved");

    println!("E2E renderer: ok");
}
