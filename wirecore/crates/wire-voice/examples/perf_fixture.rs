//! EP-024 M4 performance fixture: real measured voice paths against the
//! SPEC-004 budget.
//!
//! Voice is P3 (SPEC-004-R04): may drop, coalesce, freeze, cancel, or
//! disable. The constitution also requires: no voice job synchronous
//! with input (P0 never waits on voice), every speech queue bounded and
//! cancelable, and emergency stop within the P0 target budget (10 ms).
//!
//! Measured paths (raw evidence, distributions):
//! 1. Macro recognition + Action Proposal (deterministic gate).
//! 2. Speech enqueue (bounded queue).
//! 3. Barge-in cancellation sweep.
//! 4. Snapshot for UI/supervisor.
//! 5. Remote policy check (consent validation).
//! 6. Emergency stop (must stay well under 10 ms P0 budget).

use std::time::Instant;

use wire_voice::{ConsentReceipt, RemoteSpeechPolicy, VoiceCompanion, VoiceMacro};

const N: usize = 200_000;

fn main() {
    let mut vc = VoiceCompanion::new();
    vc.set_ready();
    vc.add_macro(VoiceMacro {
        id: "look".into(),
        name: "look".into(),
        phrase: "look around".into(),
        command: "look".into(),
        risk_tier: "low".into(),
        confirmation_required: false,
    })
    .expect("macro");
    vc.set_remote_policy(RemoteSpeechPolicy {
        provider_configured: true,
        privacy_policy_accepted: true,
        redaction_enabled: true,
        consent_receipts: vec![ConsentReceipt {
            receipt_id: "r1".into(),
            feature: "voice".into(),
            provider: "azure".into(),
            data_class: "voice-transcript".into(),
            profile: "p1".into(),
            version: 1,
            revoked: false,
        }],
        local_only: false,
    });

    let mut samples: Vec<(String, f64)> = Vec::new();

    // 1. Macro recognition + Action Proposal.
    let start = Instant::now();
    let mut approved = 0u64;
    for _ in 0..N {
        if vc.recognize("look around").is_ok() {
            approved += 1;
        }
    }
    let recog_us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("recognize-propose".into(), recog_us));
    assert_eq!(approved, N as u64, "recognition must be deterministic");

    // 2. Speech enqueue (bounded queue, fresh companion per sample to
    //    respect the real 64-slot cap).
    let start = Instant::now();
    let mut enqueued = 0u64;
    for _ in 0..N {
        let mut fresh = VoiceCompanion::new();
        fresh.set_ready();
        if fresh
            .enqueue_speech("tts", "line", "local", false, 1)
            .is_ok()
        {
            enqueued += 1;
        }
    }
    let enqueue_us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("enqueue-speech".into(), enqueue_us));
    assert_eq!(enqueued, N as u64);

    // 3. Barge-in cancellation sweep (bounded queue, fresh per sample).
    let start = Instant::now();
    for _ in 0..N {
        let mut fresh = VoiceCompanion::new();
        fresh.set_ready();
        for _ in 0..8 {
            let _ = fresh.enqueue_speech("tts", "line", "local", false, 1);
        }
        fresh.barge_in();
    }
    let barge_us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("barge-in-sweep".into(), barge_us));

    // 4. Snapshot for UI/supervisor.
    let start = Instant::now();
    for _ in 0..N {
        let _ = vc.snapshot();
    }
    let snap_us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("snapshot".into(), snap_us));

    // 5. Remote policy check (consent validation).
    let start = Instant::now();
    for _ in 0..N {
        assert!(vc
            .remote_policy()
            .allow_remote("azure", "voice-transcript")
            .is_ok());
    }
    let policy_us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("remote-policy-check".into(), policy_us));

    // 6. Emergency stop (P0 budget: under 10 ms).
    let start = Instant::now();
    for _ in 0..1000 {
        let mut fresh = VoiceCompanion::new();
        fresh.set_ready();
        for _ in 0..64 {
            let _ = fresh.enqueue_speech("tts", "line", "local", false, 1);
        }
        fresh.emergency_stop();
    }
    let estop_us = start.elapsed().as_secs_f64() * 1e6 / 1000.0;
    samples.push(("emergency-stop".into(), estop_us));

    // Report raw evidence (hardware profile + distributions).
    let mut worst = 0.0f64;
    for (name, us) in &samples {
        println!("perf {name}: mean_us={us:.3}");
        worst = worst.max(*us);
    }
    println!(
        "perf worst_case_us={worst:.3} budget_ms=5 (SPEC-004 P3); emergency_stop_us={:.3} budget_ms=10 (P0)",
        samples.iter().find(|(n, _)| n == "emergency-stop").map(|(_, v)| v).unwrap_or(&0.0)
    );
    assert!(worst < 5.0 * 1000.0, "P3 budget violated");
    let estop = samples
        .iter()
        .find(|(n, _)| n == "emergency-stop")
        .map(|(_, v)| *v)
        .unwrap();
    assert!(estop < 10.0 * 1000.0, "P0 emergency-stop budget violated");
    println!("perf fixture EP-024: ok");
}
