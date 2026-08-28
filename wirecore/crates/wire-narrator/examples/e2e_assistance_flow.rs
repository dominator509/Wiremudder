//! EP-020 M3 E2E: full assistance user-visible flow.
//!
//! Builds a real quest log with an observed quest and an inferred quest
//! (uncertainty visible), a bounded tactical snapshot, then narrates both
//! through the Personal Narrator with source disclosure. Redacts secrets
//! (including repeated markers) and proves the narrator never sends
//! commands. All through the real crates (wire-narrator -> wire-quest ->
//! wire-tactical).
//!
//! Run: cargo run --example e2e_assistance_flow

use wire_narrator::{Narrator, NarratorError};
use wire_quest::{QuestLog, QuestState};
use wire_tactical::{TacticalHud, TacticalSnapshot};

fn main() {
    let mut log = QuestLog::new();
    log.track(
        "q-observed",
        "Deliver the package",
        QuestState::Observed,
        "the courier handed you a package",
        "room:post",
        1,
    )
    .expect("track observed quest");
    log.track(
        "q-inferred",
        "Find the key",
        QuestState::Inferred,
        "the guard mentioned a key",
        "room:gate",
        2,
    )
    .expect("track inferred quest");

    let mut hud = TacticalHud::new();
    hud.update(
        TacticalSnapshot {
            room: "crossroads".into(),
            health_pct: 80,
            energy_pct: 50,
            nearby_entities: vec!["guard".into()],
            threat_level: "low".into(),
            at_ms: 3,
        },
        3,
    )
    .expect("tactical update");

    let mut narrator = Narrator::new();

    // Source-disclosing summaries with visible uncertainty.
    let quest_text = narrator
        .summarize_quest(&log, "q-inferred")
        .expect("quest summary");
    assert!(quest_text.contains("uncertainty"));
    let tactical_text = narrator.summarize_tactical(&hud);
    assert!(tactical_text.contains("crossroads"));

    // Narration is read-only text; redaction scrubs full token values.
    let (redacted, was_redacted) = narrator.redact(
        "key is sk-abcdef123 and password=hunter2 and sk-zzz999",
    );
    assert!(was_redacted);
    assert!(!redacted.contains("sk-abcdef123"));
    assert!(!redacted.contains("hunter2"));
    assert!(!redacted.contains("sk-zzz999"));

    // Load shedding drops narration when busy (typed error, no send).
    narrator.set_load_shedding(true);
    let err = narrator
        .narrate("busy", "quest", &[], false, 4)
        .expect_err("load shedding must reject");
    assert_eq!(err, NarratorError::LoadShedding);

    println!("E2E assistance: ok");
}
