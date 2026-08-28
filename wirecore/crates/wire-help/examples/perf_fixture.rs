//! EP-027 M4 performance fixture: real measured help paths against the
//! SPEC-004 budgets.
//!
//! Help is non-blocking (SPEC-018-R10) and indexing is P4
//! (SPEC-018 Performance: pauses during active gameplay). SPEC-004-R11
//! target: input under 5 ms; lookups must never block settings or
//! gameplay.
//!
//! Measured paths (raw evidence, distributions):
//! 1. Index source add (reproducible ingestion).
//! 2. Help answer lookup (bounded, non-blocking).
//! 3. Ask-context build with sanitization.
//! 4. Coach propose.
//! 5. Source-index local file scan (secret/ignore aware).
//! 6. CLI help render (parity path).

use std::time::Instant;

use wire_help::{CoachStep, FieldHelp, HelpEngine, SourceKind};

const N: usize = 100_000;

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
    let mut samples: Vec<(String, f64)> = Vec::new();

    // 1. Index source add.
    let start = Instant::now();
    for i in 0..N {
        let mut e = HelpEngine::new("1");
        let _ = e.add_source(SourceKind::Docs, &format!("d{i}"), "body", "1");
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("index-add".into(), us));

    // 2. Help answer lookup.
    let e2 = base();
    let mut versions = std::collections::BTreeMap::new();
    versions.insert("docs".to_string(), "1.0.0".to_string());
    versions.insert("command-catalog".to_string(), "1.0.0".to_string());
    let start = Instant::now();
    for _ in 0..N {
        let _ = e2.answer("connect", &versions);
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("answer-lookup".into(), us));

    // 3. Ask-context build with sanitization.
    let mut e3 = base();
    let start = Instant::now();
    for _ in 0..N {
        let _ = e3.build_ask_context(
            "port",
            "state=ready token=abc",
            "",
            &["intro".into()],
            &["connect".into()],
            &[],
            &[],
        );
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("ask-context".into(), us));

    // 4. Coach propose.
    let mut e4 = base();
    e4.add_coach_step(CoachStep {
        id: "s1".into(),
        title: "t".into(),
        explanation: "e".into(),
        proposal: "p".into(),
        safe_default: "".into(),
    })
    .unwrap();
    let start = Instant::now();
    for _ in 0..N {
        let _ = e4.propose("s1");
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("coach-propose".into(), us));

    // 5. Source-index local file scan (secret/ignore aware).
    let mut e5 = base();
    e5.enable_source_index(true, true);
    let start = Instant::now();
    for i in 0..N {
        let _ = e5.index_local_file(&format!("src/file{i}.rs"), "pub fn f() {}");
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("source-index-scan".into(), us));

    // 6. CLI help render (parity path).
    let e6 = base();
    let start = Instant::now();
    for _ in 0..N {
        let _ = e6.cli_help("connect");
    }
    let us = start.elapsed().as_secs_f64() * 1e6 / N as f64;
    samples.push(("cli-help".into(), us));

    let mut worst = 0.0f64;
    for (name, us) in &samples {
        println!("perf {name}: mean_us={us:.3}");
        worst = worst.max(*us);
    }
    println!(
        "perf worst_case_us={worst:.3} budget_us=5000 (SPEC-004 input/lookup; SPEC-018-R10 non-blocking)"
    );
    assert!(worst < 5000.0, "help lookup budget violated");
    println!("perf fixture EP-027: ok");
}
