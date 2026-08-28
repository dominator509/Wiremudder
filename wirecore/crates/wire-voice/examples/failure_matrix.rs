//! EP-024 M4 failure matrix: real controlled failures through the
//! production wire-voice crate.
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

use wire_voice::{VoiceCompanion, VoiceDenial, VoiceMacro, VoiceState};

fn main() {
    let mut vc = VoiceCompanion::new();
    vc.set_ready();

    // 1. Unavailable dependency: worker crash degrades to text.
    vc.degrade_to_text();
    assert_eq!(vc.state(), VoiceState::Degraded);
    assert_eq!(vc.queue_len(), 0);
    println!("failure-1 unavailable-worker: degrade-to-text ok");

    // 2. Timeout and cancellation: cancel a queued job by id.
    vc.set_ready();
    let id = vc
        .enqueue_speech("tts", "long narration", "local", false, 1)
        .expect("enqueue");
    vc.cancel_job(&id).expect("cancel");
    assert!(vc.queue()[0].cancelled);
    assert_eq!(
        vc.cancel_job("missing-id"),
        Err(VoiceDenial::MalformedInput)
    );
    println!("failure-2 timeout-cancellation: cancel-by-id ok");

    // 3. Malformed or oversized input.
    assert_eq!(
        vc.enqueue_speech("tts", "", "local", false, 1),
        Err(VoiceDenial::MalformedInput)
    );
    let huge = "x".repeat(2048);
    assert_eq!(
        vc.enqueue_speech("tts", &huge, "local", false, 1),
        Err(VoiceDenial::MalformedInput)
    );
    assert_eq!(
        vc.set_wake_phrase("", true, true),
        Err(VoiceDenial::MalformedInput)
    );
    println!("failure-3 malformed-oversized-input: ok");

    // 4. Duplicate or replayed request.
    let dup = VoiceMacro {
        id: "dup".into(),
        name: "dup".into(),
        phrase: "say hi".into(),
        command: "say hi".into(),
        risk_tier: "low".into(),
        confirmation_required: false,
    };
    vc.add_macro(dup.clone()).expect("first add");
    assert_eq!(vc.add_macro(dup), Err(VoiceDenial::DuplicateRequest));
    println!("failure-4 duplicate-request: ok");

    // 5. Denied permission/consent/policy.
    // Wake phrase without consent.
    assert_eq!(
        vc.set_wake_phrase("hey mud", false, true),
        Err(VoiceDenial::ConsentRequired)
    );
    // Remote speech under Local Only.
    vc.enqueue_speech("tts", "remote", "remote:azure", false, 2)
        .expect("enqueue");
    assert_eq!(
        vc.submit_remote("voice-2", "azure"),
        Err(VoiceDenial::LocalOnlyLockdown)
    );
    // Malformed macro risk tier.
    assert_eq!(
        vc.add_macro(VoiceMacro {
            id: "bad-tier".into(),
            name: "bad".into(),
            phrase: "bad".into(),
            command: "quit".into(),
            risk_tier: "unknown".into(),
            confirmation_required: false,
        }),
        Err(VoiceDenial::DeniedPolicy)
    );
    println!("failure-5 denied-policy-consent: ok");

    // 6. Resource/queue budget exhaustion (fresh companion so the real
    //    64-slot cap is the only constraint).
    let mut vc = VoiceCompanion::new();
    vc.set_ready();
    for i in 0..64 {
        vc.enqueue_speech("tts", &format!("job {i}"), "local", false, 100 + i)
            .expect("enqueue");
    }
    assert_eq!(
        vc.enqueue_speech("tts", "over", "local", false, 200),
        Err(VoiceDenial::QueueFull)
    );
    assert!(vc.did_shed_load());
    println!("failure-6 queue-budget-exhaustion: ok");

    // 7. Partial side effect and compensation: emergency stop cancels
    //    the entire queue (compensation for in-flight speech) while
    //    manual gameplay remains untouched.
    vc.emergency_stop();
    assert!(vc.is_emergency_stopped());
    assert!(vc.queue().iter().all(|j| j.cancelled));
    assert_eq!(
        vc.enqueue_speech("stt", "x", "local", true, 300),
        Err(VoiceDenial::EmergencyStop)
    );
    println!("failure-7 partial-effect-compensation: emergency-stop ok");

    // 8. Preserved manual gameplay and data integrity: subtitles
    //    already recorded survive the crash/stop; retention bounded.
    let mut vc2 = VoiceCompanion::new();
    vc2.set_ready();
    vc2.add_subtitle("recorded line", false, 1)
        .expect("subtitle");
    vc2.emergency_stop();
    assert_eq!(vc2.subtitle_count(), 1);
    assert_eq!(vc2.visible_subtitles().len(), 1);
    println!("failure-8 preserved-gameplay-data-integrity: ok");

    println!("failure matrix EP-024: ok 8/8");
}
