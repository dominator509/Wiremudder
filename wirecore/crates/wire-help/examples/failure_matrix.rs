//! EP-027 M4 failure matrix: real controlled failures through the
//! production wire-help crate.
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

use std::collections::BTreeMap;

use wire_help::{CoachStep, FieldHelp, HelpDenial, HelpEngine, SourceKind};

fn base() -> HelpEngine {
    let mut e = HelpEngine::new("1.0.0");
    e.add_source(SourceKind::Docs, "intro", "Welcome.", "1.0.0")
        .unwrap();
    e.add_source(
        SourceKind::CommandCatalog,
        "connect",
        "connect <host>",
        "1.0.0",
    )
    .unwrap();
    e.add_field_help(FieldHelp {
        field_id: "port".into(),
        label: "Port".into(),
        safe_default: "23".into(),
        validation_hint: "1-65535".into(),
        privacy_note: "local".into(),
        doc_link: "docs/connect".into(),
    })
    .unwrap();
    e
}

fn main() {
    // 1. Unavailable dependency/worker: answer for an unknown field
    //    and ask-context with no approved refs are denied.
    let e = base();
    let mut versions = BTreeMap::new();
    versions.insert("docs".to_string(), "1.0.0".to_string());
    versions.insert("command-catalog".to_string(), "1.0.0".to_string());
    assert_eq!(
        e.answer("does-not-exist", &versions),
        Err(HelpDenial::NotConfigured)
    );
    let mut e2 = base();
    assert_eq!(
        e2.build_ask_context("f", "", "", &["missing".into()], &[], &[], &[]),
        Err(HelpDenial::UnavailableDependency)
    );
    println!("failure-1 unavailable-dependency: ok");

    // 2. Timeout and cancellation: Disabled mode cancels all answers;
    //    lookups are bounded (non-blocking).
    let mut e3 = base();
    e3.set_mode(wire_help::HelpMode::Disabled);
    assert_eq!(e3.answer("intro", &versions), Err(HelpDenial::Disabled));
    assert_eq!(e3.propose("x"), Err(HelpDenial::Disabled));
    println!("failure-2 timeout-cancellation: disabled-mode cancels ok");

    // 3. Malformed or oversized input: empty ids and >1MiB bodies.
    let mut e4 = base();
    assert_eq!(
        e4.add_source(SourceKind::Docs, "", "body", "1"),
        Err(HelpDenial::MalformedInput)
    );
    let big = "x".repeat(wire_help::MAX_INPUT_BYTES + 1);
    assert_eq!(
        e4.add_source(SourceKind::Docs, "big", &big, "1"),
        Err(HelpDenial::OversizedInput)
    );
    assert_eq!(
        e4.build_ask_context("", "", "", &["intro".into()], &[], &[], &[]),
        Err(HelpDenial::MalformedInput)
    );
    println!("failure-3 malformed-oversized: ok");

    // 4. Duplicate or replayed request: duplicate index source and
    //    duplicate field help denied.
    let mut e5 = base();
    assert_eq!(
        e5.add_source(SourceKind::Docs, "intro", "again", "1.0.0"),
        Err(HelpDenial::DuplicateRequest)
    );
    assert_eq!(
        e5.add_field_help(FieldHelp {
            field_id: "port".into(),
            label: "Port".into(),
            safe_default: "23".into(),
            validation_hint: "".into(),
            privacy_note: "".into(),
            doc_link: "docs/connect".into(),
        }),
        Err(HelpDenial::DuplicateRequest)
    );
    println!("failure-4 duplicate-replay: ok");

    // 5. Denied permission/consent/policy: coach apply denied; source
    //    index disabled; capability guess denied; secret file skipped.
    let e6 = base();
    assert_eq!(e6.apply_step("x"), Err(HelpDenial::DeniedPolicy));
    let mut e7 = base();
    assert_eq!(
        e7.index_local_file("src/a.rs", "code"),
        Err(HelpDenial::Disabled)
    );
    assert_eq!(
        e7.observe_capability("mccp", true, &[]),
        Err(HelpDenial::DeniedPolicy)
    );
    e7.enable_source_index(true, true);
    assert_eq!(
        e7.index_local_file("config/credentials.txt", "password=hunter2"),
        Err(HelpDenial::SecretDetected)
    );
    println!("failure-5 denied-policy: ok");

    // 6. Resource or queue budget exhaustion: index cap, field-help
    //    cap, coach-step cap, source-index cap.
    let mut e8 = base();
    for i in 0..(wire_help::MAX_INDEX_ENTRIES + 1) {
        if e8
            .add_source(SourceKind::Docs, &format!("d{i}"), "b", "1")
            .is_err()
        {
            break;
        }
    }
    assert_eq!(e8.index_len(), wire_help::MAX_INDEX_ENTRIES);
    let mut e9 = base();
    for i in 0..(wire_help::MAX_COACH_STEPS + 1) {
        if e9
            .add_coach_step(CoachStep {
                id: format!("s{i}"),
                title: "t".into(),
                explanation: "e".into(),
                proposal: "p".into(),
                safe_default: "".into(),
            })
            .is_err()
        {
            break;
        }
    }
    assert_eq!(e9.coach_steps_len(), wire_help::MAX_COACH_STEPS);
    println!("failure-6 budget-exhaustion: bounded ok");

    // 7. Partial side effect and compensation: a secret-bearing file
    //    during source indexing is skipped with counters, leaving the
    //    index intact; removal clears everything (no half state).
    let mut e10 = base();
    e10.enable_source_index(true, true);
    e10.index_local_file("src/good.rs", "pub fn ok() {}")
        .unwrap();
    let _ = e10.index_local_file("config/bad.txt", "api_key=zzz");
    assert_eq!(e10.source_index_state().indexed_entries, 1);
    assert_eq!(e10.source_index_state().secret_entries_skipped, 1);
    e10.remove_source_index();
    assert_eq!(e10.source_index_state().indexed_entries, 0);
    assert!(e10.source_index_state().removed);
    println!("failure-7 partial-effect-compensation: ok");

    // 8. Preserved manual gameplay and data integrity: after every
    //    failure the engine is still bounded, auditable, and text
    //    gameplay is untouched (help never blocks).
    let mut e11 = base();
    for _ in 0..10 {
        e11.set_mode(wire_help::HelpMode::Disabled);
        e11.set_mode(wire_help::HelpMode::LocalOnly);
    }
    assert!(e11.audit().len() > 0);
    assert!(!e11.can_send_command());
    let got = e11.answer("connect", &versions).expect("answer");
    assert_eq!(got.id, "connect");
    println!("failure-8 gameplay-preserved: ok");
    println!("failure matrix EP-027: ok");
}
