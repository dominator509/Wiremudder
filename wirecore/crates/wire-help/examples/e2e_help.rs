//! EP-027 M3 e2e: real user-visible help, coach, and source-index flow
//! through the production wire-help crate.
//!
//! Proves the integration surface:
//! 1. Help content is generated from accepted sources.
//! 2. AI help receives only scoped sanitized context.
//! 3. Coach cannot mutate protected settings or send commands.
//! 4. Source index is opt-in, local, idle, and removable.
//! 5. Capability detection is evidence-based.
//! 6. CLI/headless help parity passes.

use std::collections::BTreeMap;

use wire_help::{CoachStep, FieldHelp, HelpDenial, HelpEngine, HelpMode, SourceKind};

fn main() {
    let mut e = HelpEngine::new("1.2.3");

    // 1. Help content is generated from accepted sources: docs,
    //    command catalog, ADRs, sanitized source references.
    e.add_source(
        SourceKind::Docs,
        "intro",
        "Welcome to WireMudder. Safe defaults are shown beside every field.",
        "1.0.0",
    )
    .expect("docs source");
    e.add_source(
        SourceKind::CommandCatalog,
        "connect",
        "connect <host> <port>",
        "1.0.0",
    )
    .expect("command source");
    e.add_source(SourceKind::Adr, "adr-0001", "Rust for WireCore.", "1.0.0")
        .expect("adr source");
    e.add_source(
        SourceKind::SourceRef,
        "src/TMedia.h",
        "sanitized reference (path only)",
        "1.0.0",
    )
    .expect("source ref");
    let mut versions: BTreeMap<String, String> = BTreeMap::new();
    versions.insert("docs".to_string(), "1.0.0".to_string());
    versions.insert("command-catalog".to_string(), "1.0.0".to_string());
    versions.insert("adr".to_string(), "1.0.0".to_string());
    versions.insert("source-ref".to_string(), "1.0.0".to_string());
    let entry = e.answer("connect", &versions).expect("indexed answer");
    assert_eq!(entry.kind, SourceKind::CommandCatalog);
    println!(
        "Help content is generated from accepted sources: {} entries",
        e.index_len()
    );

    // Field help bubbles with safe defaults, validation hints, privacy
    // notes, and documentation links.
    e.add_field_help(FieldHelp {
        field_id: "server-port".into(),
        label: "Server port".into(),
        safe_default: "23".into(),
        validation_hint: "1-65535".into(),
        privacy_note: "Stored locally only".into(),
        doc_link: "docs/connect".into(),
    })
    .expect("field help");
    let bubble = e.field_help("server-port").expect("bubble");
    assert_eq!(bubble.safe_default, "23");
    println!("Help bubbles carry safe defaults, validation hints, privacy notes, doc links: ok");

    // 2. AI help receives only scoped sanitized context.
    let ctx = e
        .build_ask_context(
            "server-port",
            "state=ready token=sekrit123",
            "port out of range",
            &["intro".into()],
            &["connect".into()],
            &["adr-0001".into()],
            &["src/TMedia.h".into()],
        )
        .expect("ask context");
    assert_eq!(ctx.field_id, "server-port");
    assert!(!ctx.sanitized_ui_state.contains("sekrit123"));
    assert_eq!(ctx.command_catalog_refs, vec!["connect"]);
    println!(
        "AI help receives only scoped sanitized context: state='{}' refs={}",
        ctx.sanitized_ui_state,
        ctx.approved_docs.len()
            + ctx.command_catalog_refs.len()
            + ctx.adr_refs.len()
            + ctx.source_refs.len()
    );

    // 3. Coach cannot mutate protected settings or send commands.
    e.add_coach_step(CoachStep {
        id: "welcome".into(),
        title: "Connect to your first world".into(),
        explanation: "Enter the address of the server you want to join.".into(),
        proposal: "Set address to the server shown in your invite.".into(),
        safe_default: "".into(),
    })
    .expect("coach step");
    let step = e.propose("welcome").expect("propose");
    assert_eq!(step.title, "Connect to your first world");
    assert_eq!(e.apply_step("welcome"), Err(HelpDenial::DeniedPolicy));
    assert!(!e.can_send_command());
    assert!(e.side_effect_free());
    println!(
        "Coach cannot mutate protected settings or send commands: apply denied, no command path"
    );

    // 4. Source index is opt-in, local, idle, and removable.
    assert!(!e.source_index_state().enabled);
    e.enable_source_index(true, true);
    assert!(e.source_index_state().enabled);
    assert!(e.source_index_state().local_only);
    assert!(e.source_index_state().idle_only);
    e.index_local_file("src/wire-help.rs", "pub fn main() {}")
        .expect("indexed");
    let skipped = e.index_local_file("config/credentials.txt", "password=hunter2");
    assert_eq!(skipped, Err(HelpDenial::SecretDetected));
    e.remove_source_index();
    assert!(e.source_index_state().removed);
    println!("Source index is opt-in, local, idle, and removable: ok");

    // 5. Capability detection is evidence-based.
    assert_eq!(
        e.observe_capability("mccp", true, &[]),
        Err(HelpDenial::DeniedPolicy)
    );
    e.observe_capability("mccp", true, &["IAC negotiation observed".to_string()])
        .expect("observed with evidence");
    assert!(!e.capability("mccp").unwrap().confirmed);
    assert!(e.confirm_capability("mccp"));
    assert_eq!(e.confirmed_capabilities().len(), 1);
    println!("Capability detection is evidence-based: guessing denied, confirmation required");

    // 6. CLI/headless help parity passes.
    let cli = e.cli_help("connect").expect("cli help");
    let ui = e.ui_help("connect").expect("ui help");
    assert_eq!(cli, ui);
    assert!(cli.contains("[command-catalog]"));
    println!("CLI/headless help parity passes: identical source, identical output");

    // Help never blocks settings interaction or gameplay.
    e.set_mode(HelpMode::Disabled);
    assert_eq!(e.answer("connect", &versions), Err(HelpDenial::Disabled));
    println!("E2E help-coach: ok");
}
