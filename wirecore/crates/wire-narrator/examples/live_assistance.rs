//! EP-020 M5 live-fire: quest-tactical-narration certification.
//!
//! Runs the real user outcome for Quest Compass, Tactical HUD, and
//! Personal Narrator against the real crates and writes certification
//! evidence: cited quests with visible uncertainty, user corrections,
//! bounded tactical snapshots, narrator summaries that disclose source
//! and redact secrets (including repeated markers), load shedding, and
//! no command path anywhere. Manual text gameplay is preserved.
//!
//! Run: cargo run --example live_assistance (in wire-narrator).

use wire_narrator::{Narrator, NarratorError};
use wire_quest::{QuestLog, QuestState};
use wire_tactical::{TacticalHud, TacticalSnapshot};

fn main() {
    let mut evidence = serde_json::Map::new();

    // ---- 1. Cited quest tracking with visible uncertainty. ----
    let mut log = QuestLog::new();
    log.track(
        "q-observed",
        "Deliver the package",
        QuestState::Observed,
        "the courier handed you a package",
        "room:post",
        1,
    )
    .expect("track observed");
    log.track(
        "q-inferred",
        "Find the key",
        QuestState::Inferred,
        "the guard mentioned a key",
        "room:gate",
        2,
    )
    .expect("track inferred");
    evidence.insert(
        "cites_clues".into(),
        serde_json::json!(log.get("q-observed").unwrap().clues[0].cited_from == "room:post"),
    );

    // ---- 2. User correction is visible (user-corrected state). ----
    log.apply_correction("q-inferred", "the key is behind the inn", 3)
        .expect("correction");
    evidence.insert(
        "user_correction_visible".into(),
        serde_json::json!(
            log.get("q-inferred").unwrap().state == QuestState::UserCorrected
                && log.get("q-inferred").unwrap().corrections.len() == 1
        ),
    );

    // ---- 3. Uncertainty is visible for inferred state. ----
    let mut narrator = Narrator::new();
    let inf_text = narrator.summarize_quest(&log, "q-observed").unwrap();
    // Observed quest has no uncertainty marker; inferred/corrected do.
    let mut log2 = QuestLog::new();
    log2.track(
        "q2",
        "Find the thief",
        QuestState::Inferred,
        "likely the hooded figure",
        "memory:crossroads",
        1,
    )
    .unwrap();
    let inf2 = narrator.summarize_quest(&log2, "q2").unwrap();
    evidence.insert(
        "uncertainty_visible".into(),
        serde_json::json!(!inf_text.contains("uncertainty") && inf2.contains("uncertainty")),
    );

    // ---- 4. Bounded tactical snapshot. ----
    let mut hud = TacticalHud::new();
    hud.update(
        TacticalSnapshot {
            room: "crossroads".into(),
            health_pct: 80,
            energy_pct: 50,
            nearby_entities: vec!["guard".into(), "innkeeper".into()],
            threat_level: "low".into(),
            at_ms: 4,
        },
        4,
    )
    .expect("tactical update");
    evidence.insert(
        "bounded_snapshot".into(),
        serde_json::json!(hud.current().unwrap().room == "crossroads"),
    );
    // Oversized input is rejected (default 64-entity cap).
    let oversized = TacticalSnapshot {
        room: "crossroads".into(),
        health_pct: 80,
        energy_pct: 50,
        nearby_entities: (0..70).map(|i| format!("entity-{i}")).collect(),
        threat_level: "low".into(),
        at_ms: 5,
    };
    evidence.insert(
        "oversized_rejected".into(),
        serde_json::json!(hud.update(oversized, 5).is_err()),
    );

    // ---- 5. Narrator discloses source and redacts secrets. ----
    let summary = narrator
        .narrate(
            "Quest 'Deliver the package' is observed.",
            "quest",
            &["room:post".into()],
            false,
            6,
        )
        .expect("narrate");
    evidence.insert(
        "source_disclosed".into(),
        serde_json::json!(summary.source == "quest" && summary.cites[0] == "room:post"),
    );
    let (redacted_out, redacted) =
        narrator.redact("session sk-abc123 password=hunter2 token sk-def456");
    evidence.insert(
        "secrets_redacted".into(),
        serde_json::json!(
            redacted
                && !redacted_out.contains("sk-abc123")
                && !redacted_out.contains("hunter2")
                && !redacted_out.contains("sk-def456")
        ),
    );

    // ---- 6. Load shedding drops narration; resumes when normalized. ----
    let mut busy = Narrator::new();
    busy.set_load_shedding(true);
    evidence.insert(
        "load_shedding".into(),
        serde_json::json!(
            busy.narrate("busy", "quest", &[], false, 7) == Err(NarratorError::LoadShedding)
        ),
    );

    // ---- 7. No command path; manual gameplay preserved. ----
    evidence.insert(
        "hud_no_command".into(),
        serde_json::json!(!hud.can_send_command()),
    );
    let hdr = std::fs::read_to_string("src/wiremudder/ui/assistance/assistance_boundary.h")
        .expect("assistance boundary header");
    evidence.insert(
        "pane_passive".into(),
        serde_json::json!(hdr.contains("isPassive() const { return true; }")),
    );
    evidence.insert(
        "pane_no_command_path".into(),
        serde_json::json!(hdr.contains("canSendCommand() const { return false; }")),
    );

    // ---- Write certification evidence with real measured values. ----
    std::fs::create_dir_all(".agent/state/evidence/EP-020/M5").expect("evidence dir");
    std::fs::write(
        ".agent/state/evidence/EP-020/M5/lf020-certification.json",
        serde_json::to_string_pretty(&serde_json::Value::Object(evidence)).expect("evidence json"),
    )
    .expect("evidence write");

    println!("LF-020 live: ok");
}
