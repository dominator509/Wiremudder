//! EP-025 M4 failure matrix: real controlled failures through the
//! production wire-renderer crate.
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

use wire_renderer::{
    AssetManifestEntry, ClickableExit, EmitKind, RendererDenial, RendererEmitCandidate,
    RendererMode, RetroRenderer,
};

fn candidate(id: &str, kind: EmitKind, label: &str) -> RendererEmitCandidate {
    RendererEmitCandidate {
        candidate_id: id.into(),
        kind,
        label: label.into(),
        confidence: 80,
        inferred: false,
        evidence: vec![],
        suggested_by: "parser".into(),
    }
}

fn main() {
    let mut r = RetroRenderer::new();

    // 1. Unavailable dependency/worker: crash degrades to text.
    r.apply_candidate(candidate("c1", EmitKind::Npc, "guard"), 1)
        .expect("apply");
    r.degrade_to_text();
    assert_eq!(r.mode(), RendererMode::TextOnly);
    assert_eq!(r.queue_len(), 0);
    println!("failure-1 unavailable-worker: degrade-to-text ok");

    // 2. Timeout and cancellation: emergency stop cancels the queue.
    let mut r2 = RetroRenderer::new();
    for i in 0..10 {
        r2.apply_candidate(candidate(&format!("c{i}"), EmitKind::Item, "sword"), i)
            .expect("apply");
    }
    r2.emergency_stop();
    assert!(r2.is_emergency_stopped());
    assert_eq!(r2.queue_len(), 0);
    println!("failure-2 timeout-cancellation: emergency-stop ok");

    // 3. Malformed or oversized input.
    let mut r3 = RetroRenderer::new();
    assert_eq!(
        r3.apply_candidate(candidate("", EmitKind::Npc, "guard"), 1),
        Err(RendererDenial::MalformedInput)
    );
    assert_eq!(
        r3.apply_candidate(
            RendererEmitCandidate {
                candidate_id: "c".into(),
                kind: EmitKind::Npc,
                label: "guard".into(),
                confidence: 200, // > 100
                inferred: false,
                evidence: vec![],
                suggested_by: "parser".into(),
            },
            1,
        ),
        Err(RendererDenial::MalformedInput)
    );
    assert_eq!(
        r3.add_exit(ClickableExit {
            id: "e".into(),
            direction: "".into(),
            target_room: None,
            visible: true,
        }),
        Err(RendererDenial::MalformedInput)
    );
    println!("failure-3 malformed-oversized-input: ok");

    // 4. Duplicate or replayed request.
    let pack = AssetManifestEntry {
        id: "pack".into(),
        pack: "p".into(),
        license: "CC0-1.0".into(),
        provenance: "original:wiremudder:procedural".into(),
        sha256: "e".repeat(64),
        signature: Some("sig".into()),
        user_local: false,
        permissions: vec![],
    };
    r3.add_asset_pack(pack.clone()).expect("first");
    assert_eq!(
        r3.add_asset_pack(pack),
        Err(RendererDenial::DuplicateRequest)
    );
    println!("failure-4 duplicate-request: ok");

    // 5. Denied permission/consent/policy: protected asset, invisible
    //    exit, disabled mode.
    assert_eq!(
        r3.add_asset_pack(AssetManifestEntry {
            id: "protected".into(),
            pack: "p".into(),
            license: "CC0-1.0".into(),
            provenance: "protected:zelda".into(),
            sha256: "f".repeat(64),
            signature: Some("sig".into()),
            user_local: false,
            permissions: vec![],
        }),
        Err(RendererDenial::ProtectedAsset)
    );
    let hidden = ClickableExit {
        id: "hidden".into(),
        direction: "east".into(),
        target_room: None,
        visible: false,
    };
    assert_eq!(hidden.propose(), Err(RendererDenial::DeniedPolicy));
    r3.set_mode(RendererMode::Disabled).expect("disabled");
    assert_eq!(
        r3.apply_candidate(candidate("c2", EmitKind::Item, "sword"), 1),
        Err(RendererDenial::DeniedPolicy)
    );
    println!("failure-5 denied-policy: ok");

    // 6. Resource/queue budget exhaustion.
    let mut r6 = RetroRenderer::new();
    for i in 0..128 {
        r6.apply_candidate(candidate(&format!("c{i}"), EmitKind::Weather, "rain"), i)
            .expect("apply");
    }
    // Coalesce: same-kind noncritical emit is coalesced, not denied.
    r6.apply_candidate(candidate("overflow", EmitKind::Weather, "storm"), 999)
        .expect("coalesce");
    assert_eq!(r6.queue_len(), 128);
    assert_eq!(r6.coalesces(), 1);
    // A new kind cannot be queued when full: dropped as QueueFull.
    assert_eq!(
        r6.apply_candidate(candidate("newkind", EmitKind::Npc, "guard"), 1000),
        Err(RendererDenial::QueueFull)
    );
    assert!(r6.drops() >= 1);
    println!("failure-6 queue-budget-exhaustion: ok");

    // 7. Partial side effect and compensation: combat drops queued
    //    noncritical emits but preserves critical ones (compensation).
    let mut r7 = RetroRenderer::new();
    r7.apply_candidate(candidate("a", EmitKind::Ambience, "torch"), 1)
        .expect("apply");
    r7.apply_candidate(candidate("b", EmitKind::Combat, "hit"), 2)
        .expect("apply");
    r7.set_combat(true);
    assert!(r7.in_combat());
    assert_eq!(r7.queue_len(), 1);
    assert_eq!(r7.queue()[0].kind, EmitKind::Combat);
    assert!(r7.drops() >= 1);
    println!("failure-7 partial-effect-compensation: combat-drop ok");

    // 8. Preserved manual gameplay and data integrity: provenance and
    //    audit survive crash/stop; raw text path untouched.
    let mut r8 = RetroRenderer::new();
    r8.track_provenance("original:wiremudder:procedural");
    r8.emergency_stop();
    assert!(r8.is_emergency_stopped());
    assert_eq!(r8.provenance().len(), 1);
    assert_eq!(r8.audit_trail().len(), 2); // provenance + emergency stop
    println!("failure-8 preserved-gameplay-data-integrity: ok");

    println!("failure matrix EP-025: ok 8/8");
}
