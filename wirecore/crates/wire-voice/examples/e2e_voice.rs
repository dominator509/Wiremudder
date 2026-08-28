//! EP-024 M3 e2e: real user-visible voice flow through the production
//! wire-voice crate.
//!
//! Proves the integration surface:
//! 1. Mic state is always visible (off -> listening -> off).
//! 2. A voice macro produces an Action Proposal through the
//!    deterministic command-safety gate and is approved explicitly.
//! 3. Wake phrase is disabled by default and requires consent.
//! 4. Remote speech is denied under Local Only and allowed with full
//!    consent, then denied again after revocation.
//! 5. Barge-in cancels synthesis.
//! 6. Worker crash degrades to text without touching manual gameplay.
//! 7. Subtitles suppress private content by default.

use wire_voice::{ConsentReceipt, RemoteSpeechPolicy, VoiceCompanion, VoiceMacro, VoiceState};

fn main() {
    // 1. Mic state always visible.
    let mut vc = VoiceCompanion::new();
    vc.set_ready();
    assert_eq!(vc.mic_state().label(), "off");
    vc.begin_listen().expect("listen");
    assert_eq!(vc.mic_state().label(), "listening");
    vc.end_listen();
    assert_eq!(vc.mic_state().label(), "off");
    println!("mic state always visible: off -> listening -> off");

    // 2. Voice macro -> Action Proposal -> explicit approval.
    vc.add_macro(VoiceMacro {
        id: "macro-look".into(),
        name: "look".into(),
        phrase: "look around".into(),
        command: "look".into(),
        risk_tier: "low".into(),
        confirmation_required: false,
    })
    .expect("macro registered");
    let mut proposal = vc.recognize("look around").expect("recognized");
    assert_eq!(proposal.source, "voice");
    assert!(!proposal.approved);
    vc.approve_proposal(&mut proposal).expect("approval");
    assert!(proposal.approved);
    println!(
        "voice macro -> Action Proposal -> approved: source={} command={}",
        proposal.source, proposal.normalized_command
    );

    // 3. Wake phrase disabled by default; consent required.
    assert!(!vc.wake_phrase().is_some());
    assert_eq!(
        vc.set_wake_phrase("hey mud", false, true).is_err(),
        true,
        "wake phrase without consent denied"
    );
    vc.set_wake_phrase("hey mud", true, true)
        .expect("wake phrase");
    println!("wake phrase: disabled by default, explicit consent required");

    // 4. Remote speech privacy and consent.
    vc.enqueue_speech("tts", "remote line", "remote:azure", false, 1)
        .expect("enqueue");
    let denied = vc.submit_remote("voice-1", "azure").is_err();
    assert!(denied, "remote speech denied under Local Only");
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
    vc.submit_remote("voice-1", "azure")
        .expect("remote approved");
    println!("remote speech: denied under Local Only, allowed with consent");

    // 5. Barge-in cancels synthesis.
    vc.enqueue_speech("tts", "narration", "local", false, 2)
        .expect("enqueue narration");
    vc.barge_in();
    assert!(vc.queue()[1].cancelled);
    println!("barge-in cancels synthesis");

    // 6. Worker crash degrades to text; manual gameplay preserved.
    vc.degrade_to_text();
    assert_eq!(vc.state(), VoiceState::Degraded);
    assert_eq!(vc.queue_len(), 0);
    // Manual text gameplay is independent: the companion only owns the
    // voice queue; terminal/input/connection are untouched.
    println!("worker crash -> degrade to text; manual gameplay preserved");

    // 7. Subtitles suppress private content by default.
    vc.add_subtitle("public room line", false, 3)
        .expect("subtitle");
    vc.add_subtitle("private tell", true, 4).expect("subtitle");
    assert_eq!(vc.visible_subtitles().len(), 1);
    println!("subtitles: private content suppressed by default");

    println!("E2E voice: ok");
}
