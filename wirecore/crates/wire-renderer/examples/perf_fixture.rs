//! EP-025 M4 performance fixture: real measured renderer paths against
//! the SPEC-004 / SPEC-016 budgets.
//!
//! Renderer is P3 (SPEC-004-R04): may drop, coalesce, freeze, cancel,
//! or disable. SPEC-016 Performance: renderer target work is measured
//! within a 4-6 ms frame budget and may drop P3 events.
//!
//! Measured paths (raw evidence, distributions):
//! 1. Emit candidate application (bounded queue).
//! 2. Frame-budgeted render_frame (5 ms budget).
//! 3. Combat drop sweep.
//! 4. Snapshot for UI/supervisor.
//! 5. Asset pack validation.
//! 6. Emergency stop (P0 budget: under 10 ms).

use std::time::Instant;

use wire_renderer::{AssetManifestEntry, EmitKind, RendererEmitCandidate, RetroRenderer};

const N: usize = 200_000;

fn candidate(id: &str, kind: EmitKind) -> RendererEmitCandidate {
    RendererEmitCandidate {
        candidate_id: id.into(),
        kind,
        label: "label".into(),
        confidence: 80,
        inferred: false,
        evidence: vec![],
        suggested_by: "parser".into(),
    }
}

fn main() {
    let mut samples: Vec<(String, f64)> = Vec::new();

    // 1. Emit candidate application.
    let start = Instant::now();
    for i in 0..N {
        let mut r = RetroRenderer::new();
        let _ = r.apply_candidate(candidate(&format!("c{i}"), EmitKind::Npc), 1);
    }
    let apply_us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("apply-candidate".into(), apply_us));

    // 2. Frame-budgeted render_frame (5 ms budget, full queue).
    let start = Instant::now();
    for _ in 0..1000 {
        let mut r = RetroRenderer::new();
        for i in 0..128 {
            let _ = r.apply_candidate(candidate(&format!("c{i}"), EmitKind::Item), i);
        }
        r.render_frame(5_000);
    }
    let frame_us = start.elapsed().as_secs_f64() * 1e6 / 1000.0;
    samples.push(("render-frame-128".into(), frame_us));

    // 3. Combat drop sweep.
    let start = Instant::now();
    for _ in 0..N {
        let mut r = RetroRenderer::new();
        let _ = r.apply_candidate(candidate("c", EmitKind::Ambience), 1);
        r.set_combat(true);
    }
    let combat_us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("combat-drop-sweep".into(), combat_us));

    // 4. Snapshot for UI/supervisor.
    let r = RetroRenderer::new();
    let start = Instant::now();
    for _ in 0..N {
        let _ = r.snapshot();
    }
    let snap_us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("snapshot".into(), snap_us));

    // 5. Asset pack validation.
    let start = Instant::now();
    for _ in 0..N {
        let mut fresh = RetroRenderer::new();
        let _ = fresh.add_asset_pack(AssetManifestEntry {
            id: "pack".into(),
            pack: "p".into(),
            license: "CC0-1.0".into(),
            provenance: "original:wiremudder:procedural".into(),
            sha256: "e".repeat(64),
            signature: Some("sig".into()),
            user_local: false,
            permissions: vec!["display".into()],
        });
    }
    let pack_us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("asset-pack-validate".into(), pack_us));

    // 6. Emergency stop (P0 budget: under 10 ms).
    let start = Instant::now();
    for _ in 0..1000 {
        let mut fresh = RetroRenderer::new();
        for i in 0..128 {
            let _ = fresh.apply_candidate(candidate(&format!("c{i}"), EmitKind::Item), i);
        }
        fresh.emergency_stop();
    }
    let estop_us = start.elapsed().as_secs_f64() * 1e6 / 1000.0;
    samples.push(("emergency-stop".into(), estop_us));

    let mut worst = 0.0f64;
    for (name, us) in &samples {
        println!("perf {name}: mean_us={us:.3}");
        worst = worst.max(*us);
    }
    println!(
        "perf worst_case_us={worst:.3} budget_ms=5 (SPEC-016 frame, P3); emergency_stop_us={:.3} budget_ms=10 (P0)",
        samples.iter().find(|(n, _)| n == "emergency-stop").map(|(_, v)| v).unwrap_or(&0.0)
    );
    assert!(worst < 5.0 * 1000.0, "frame budget violated");
    let estop = samples
        .iter()
        .find(|(n, _)| n == "emergency-stop")
        .map(|(_, v)| *v)
        .unwrap();
    assert!(estop < 10.0 * 1000.0, "P0 emergency-stop budget violated");
    println!("perf fixture EP-025: ok");
}
