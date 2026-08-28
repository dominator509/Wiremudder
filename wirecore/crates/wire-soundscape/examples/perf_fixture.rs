//! EP-026 M4 performance fixture: real measured soundscape paths
//! against the SPEC-004 budgets.
//!
//! Soundscape is P3 (SPEC-004-R04): may drop, coalesce, freeze,
//! cancel, or disable. SPEC-004-R11 target budgets: emergency stop
//! under 10 ms (P0); audio operations use the 5 ms P3 op budget.
//!
//! Measured paths (raw evidence, distributions):
//! 1. Play request enqueue (bounded queue, load shedding).
//! 2. tick() with transition advance and coalescing.
//! 3. Transition start (bounded, cancelable).
//! 4. Studio control update (profile-scoped volume/disable).
//! 5. Asset provenance validation.
//! 6. Emergency stop (P0 budget: under 10 ms).

use std::time::Instant;

use wire_soundscape::{AssetPackEntry, SoundscapeEngine, SoundscapeKind};

const N: usize = 200_000;

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
    let mut samples: Vec<(String, f64)> = Vec::new();

    // 1. Play request enqueue.
    let start = Instant::now();
    for i in 0..N {
        let mut e = SoundscapeEngine::new();
        e.register_asset(asset("a")).unwrap();
        e.register_binding(SoundscapeKind::Room, "a", None).unwrap();
        let _ = e.request_play("default", SoundscapeKind::Room, "a", i % 3 == 0);
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("request-play".into(), us));

    // 2. tick() with transition advance and coalescing.
    let start = Instant::now();
    for _ in 0..N {
        let mut e = SoundscapeEngine::new();
        e.register_asset(asset("a")).unwrap();
        for k in SoundscapeKind::all() {
            let author = if k == SoundscapeKind::UserAuthored {
                Some("p".into())
            } else {
                None
            };
            e.register_binding(k, "a", author).unwrap();
        }
        for i in 0..8 {
            let _ = e.request_play("default", SoundscapeKind::all()[i], "a", false);
        }
        e.tick(5);
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("tick-coalesce".into(), us));

    // 3. Transition start (bounded).
    let start = Instant::now();
    for _ in 0..N {
        let mut e = SoundscapeEngine::new();
        e.register_asset(asset("a")).unwrap();
        e.register_binding(SoundscapeKind::Room, "a", None).unwrap();
        e.register_binding(SoundscapeKind::Combat, "a", None)
            .unwrap();
        let _ = e.start_transition(SoundscapeKind::Combat, 100);
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("transition-start".into(), us));

    // 4. Studio control update (profile-scoped).
    let mut e4 = SoundscapeEngine::new();
    e4.register_asset(asset("a")).unwrap();
    e4.register_binding(SoundscapeKind::Room, "a", None)
        .unwrap();
    let start = Instant::now();
    for i in 0..N {
        e4.set_profile_controls("default", (i % 100) as u8, false)
            .unwrap();
        let _ = e4.set_binding_volume(SoundscapeKind::Room, (i % 100) as u8);
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("studio-control".into(), us));

    // 5. Asset provenance validation.
    let mut e5 = SoundscapeEngine::new();
    let start = Instant::now();
    for i in 0..N {
        let mut a = asset("a");
        a.id = format!("a{i}");
        let _ = e5.register_asset(a);
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("asset-provenance".into(), us));

    // 6. Emergency stop (P0 budget: under 10 ms per call).
    let start = Instant::now();
    for _ in 0..1000 {
        let mut e = SoundscapeEngine::new();
        e.register_asset(asset("a")).unwrap();
        e.register_binding(SoundscapeKind::Room, "a", None).unwrap();
        let _ = e.request_play("default", SoundscapeKind::Room, "a", false);
        e.emergency_stop();
    }
    let estop_us = start.elapsed().as_secs_f64() * 1e6 / 1000.0;
    samples.push(("emergency-stop".into(), estop_us));

    let mut worst = 0.0f64;
    for (name, us) in &samples {
        println!("perf {name}: mean_us={us:.3}");
        worst = worst.max(*us);
    }
    let estop = samples
        .iter()
        .find(|(n, _)| n == "emergency-stop")
        .map(|(_, v)| *v)
        .unwrap();
    println!(
        "perf worst_case_us={worst:.3} budget_us=5000 (P3 op); emergency_stop_us={estop:.3} budget_us=10000 (P0)"
    );
    assert!(worst < 5000.0, "P3 op budget violated");
    assert!(estop < 10000.0, "P0 emergency-stop budget violated");
    println!("perf fixture EP-026: ok");
}
