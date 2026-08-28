//! EP-027 M4 security matrix: provenance, injection, secret, and
//! permission boundaries for the help, coach, and source index.
//!
//! Required security proofs (node contract, SPEC-022, SPEC-018):
//! 1. The coach cannot mutate protected settings or send commands
//!    (SPEC-018-R06).
//! 2. AI help receives only scoped sanitized context; secrets are
//!    redacted (SPEC-018-R02).
//! 3. Source indexing is secret-aware and ignore-file-aware
//!    (SPEC-018-R05).
//! 4. Help modes are local-only and remote-redacted or disabled
//!    (SPEC-018-R03).
//! 5. Prompt injection cannot override help policy or command safety.

use wire_help::{CoachStep, FieldHelp, HelpDenial, HelpEngine, HelpMode, SourceKind};

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
    e
}

fn main() {
    // 1. Coach cannot mutate or send commands.
    let e = base();
    assert_eq!(e.apply_step("anything"), Err(HelpDenial::DeniedPolicy));
    assert!(!e.can_send_command());
    assert!(e.side_effect_free());
    println!("security-1 coach-no-mutation ok");

    // 2. AI context is scoped and sanitized; secrets redacted.
    let mut e2 = base();
    let ctx = e2
        .build_ask_context(
            "port",
            "token=abc123 password=letmein",
            "",
            &["intro".into()],
            &["connect".into()],
            &[],
            &[],
        )
        .expect("context");
    assert!(!ctx.sanitized_ui_state.contains("abc123"));
    assert!(!ctx.sanitized_ui_state.contains("letmein"));
    assert!(ctx.sanitized_ui_state.contains("[REDACTED]"));
    // only approved refs survive
    let ctx2 = e2
        .build_ask_context("p", "", "", &["not-indexed".into()], &[], &[], &[])
        .unwrap_err();
    assert_eq!(ctx2, HelpDenial::UnavailableDependency);
    println!("security-2 sanitized-scoped-context ok");

    // 3. Source indexing secret-aware and ignore-aware.
    let mut e3 = base();
    e3.enable_source_index(true, true);
    assert_eq!(
        e3.index_local_file("config/credentials.txt", "password=hunter2"),
        Err(HelpDenial::SecretDetected)
    );
    assert_eq!(
        e3.index_local_file("target/build/app", "binary"),
        Err(HelpDenial::DeniedPolicy)
    );
    assert_eq!(
        e3.index_local_file(".env", "FOO=bar"),
        Err(HelpDenial::DeniedPolicy)
    );
    assert_eq!(e3.source_index_state().secret_entries_skipped, 1);
    assert!(e3.source_index_state().ignored_entries_skipped >= 2);
    println!("security-3 source-index-secret-aware ok");

    // 4. Help modes: remote-redacted is allowed; disabled denies all.
    let mut e4 = base();
    e4.set_mode(HelpMode::RemoteRedacted);
    assert_eq!(e4.mode(), HelpMode::RemoteRedacted);
    // remote-redacted still serves local help (no remote egress)
    let mut versions = std::collections::BTreeMap::new();
    versions.insert("docs".to_string(), "1.0.0".to_string());
    assert!(e4.answer("intro", &versions).is_ok());
    e4.set_mode(HelpMode::Disabled);
    assert_eq!(e4.answer("intro", &versions), Err(HelpDenial::Disabled));
    println!("security-4 help-modes ok");

    // 5. Prompt injection cannot override policy: injected ids and
    //    bodies are stored as inert data; coach/command safety intact.
    let mut e5 = base();
    let injected = "connect; drop table players; --";
    assert!(e5.answer(injected, &versions).is_err());
    e5.add_coach_step(CoachStep {
        id: "s1".into(),
        title: "t".into(),
        explanation: "explain; send killall mudlet".into(),
        proposal: "propose".into(),
        safe_default: "".into(),
    })
    .unwrap();
    let step = e5.propose("s1").unwrap();
    assert!(step.explanation.contains("killall")); // inert data
    assert_eq!(e5.apply_step("s1"), Err(HelpDenial::DeniedPolicy));
    assert!(!e5.can_send_command());
    println!("security-5 injection-cannot-override ok");
    println!("security matrix EP-027: ok");
}
