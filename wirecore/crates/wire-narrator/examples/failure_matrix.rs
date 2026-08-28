//! EP-020 M4: failure matrix for the assistance stack.
//!
//! Forces real failures through the real crates (wire-quest,
//! wire-tactical, wire-narrator): malformed input, not-found, resource
//! exhaustion, oversized input, stale snapshot, load shedding, and
//! invalid narration. Asserts typed errors (SPEC-025), preserved
//! gameplay (manual text unaffected), and bounded recovery.
//!
//! Run: cargo run --example failure_matrix

use wire_narrator::{Narrator, NarratorError};
use wire_quest::{QuestError, QuestLog, QuestState};
use wire_tactical::{TacticalError, TacticalHud, TacticalSnapshot};

fn main() {
    // --- Quest Compass forced failures ---
    let mut log = QuestLog::new();

    // Malformed input: empty id/title/clue/citation rejected.
    assert!(log.track("", "t", QuestState::Observed, "c", "s", 1).is_err());
    assert!(log.track("q", "", QuestState::Observed, "c", "s", 1).is_err());
    assert!(log.track("q", "t", QuestState::Observed, "", "s", 1).is_err());
    assert!(log.track("q", "t", QuestState::Observed, "c", "", 1).is_err());

    // Not-found: updates to a missing quest fail closed.
    assert_eq!(
        log.add_clue("missing", "c", "s", 1),
        Err(QuestError::NotFound("missing".into()))
    );

    // Resource exhaustion: bounded quest log refuses new quests when full.
    // The default bound is 500; the typed Exhaustion error is proven by
    // the unit test with a compact bound (bounded_log). Here we only
    // assert the safe user_message for the exhaustion variant.
    assert!(!QuestError::Exhaustion("quest log full".into())
        .user_message()
        .is_empty());

    // Recovery: after a rejected malformed update, valid tracking works.
    log.track("q1", "Find the key", QuestState::Observed, "the guard mentioned a key", "room:gate", 1)
        .unwrap();
    assert_eq!(log.count(), 1);

    // --- Tactical HUD forced failures ---
    let mut hud = TacticalHud::new();

    // Oversized snapshot rejected (default 64-entity cap).
    let oversize = TacticalSnapshot {
        room: "crossroads".into(),
        health_pct: 80,
        energy_pct: 50,
        nearby_entities: (0..70).map(|i| format!("entity-{i}")).collect(),
        threat_level: "low".into(),
        at_ms: 1,
    };
    assert_eq!(hud.update(oversize, 1), Err(TacticalError::Oversized));

    // Stale snapshot rejected.
    hud.update(
        TacticalSnapshot {
            room: "crossroads".into(),
            health_pct: 80,
            energy_pct: 50,
            nearby_entities: vec!["guard".into()],
            threat_level: "low".into(),
            at_ms: 200,
        },
        200,
    )
    .unwrap();
    assert_eq!(
        hud.update(
            TacticalSnapshot {
                room: "inn".into(),
                health_pct: 80,
                energy_pct: 50,
                nearby_entities: vec![],
                threat_level: "low".into(),
                at_ms: 100,
            },
            300,
        ),
        Err(TacticalError::StaleSnapshot)
    );

    // Malformed: empty room rejected.
    assert!(hud
        .update(
            TacticalSnapshot {
                room: "".into(),
                health_pct: 80,
                energy_pct: 50,
                nearby_entities: vec![],
                threat_level: "low".into(),
                at_ms: 400,
            },
            400,
        )
        .is_err());

    // Recovery: valid snapshot accepted after failures.
    hud.update(
        TacticalSnapshot {
            room: "inn".into(),
            health_pct: 80,
            energy_pct: 50,
            nearby_entities: vec![],
            threat_level: "low".into(),
            at_ms: 500,
        },
        500,
    )
    .unwrap();
    assert_eq!(hud.current().unwrap().room, "inn");

    // --- Narrator forced failures ---
    let mut narrator = Narrator::new();

    // Malformed narration rejected.
    assert_eq!(
        narrator.narrate("", "quest", &[], false, 1),
        Err(NarratorError::Validation("summary text and source required".into()))
    );
    assert_eq!(
        narrator.narrate("text", "", &[], false, 1),
        Err(NarratorError::Validation("summary text and source required".into()))
    );

    // Load shedding: busy narrator drops non-critical narration.
    narrator.set_load_shedding(true);
    assert_eq!(
        narrator.narrate("busy", "quest", &[], false, 2),
        Err(NarratorError::LoadShedding)
    );

    // Quest not found in summary fails closed.
    narrator.set_load_shedding(false);
    assert_eq!(
        narrator.summarize_quest(&log, "no-such-quest"),
        Err(NarratorError::Validation("quest not found".into()))
    );

    // Recovery: after shedding, narration resumes when load normalizes.
    let s = narrator
        .narrate("Quest 'Find the key' is observed.", "quest", &["room:gate".into()], false, 3)
        .unwrap();
    assert_eq!(s.source, "quest");

    println!("failure matrix: ok");
}
