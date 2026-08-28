//! EP-021 M3 E2E: full world-memory user-visible flow.
//!
//! Runs the real memory pipeline through the real crates: World Brain
//! observes a room fact with provenance, a new observation supersedes
//! it, a user correction supersedes without erasing history; World Bible
//! holds region continuity metadata and exports deterministically; Time
//! Machine snapshots the compacted view, restore is denied until
//! user-approval, then restore returns the checkpoint. All surfaces are
//! observers: nothing sends commands.
//!
//! Run: cargo run --example e2e_world_memory_flow

use std::collections::BTreeMap;

use wire_time_machine::TimeMachine;
use wire_world_bible::WorldBible;
use wire_world_brain::{Sensitivity, Supersession, WorldBrain};

fn main() {
    // ---- 1. World Brain: provenance + correction. ----
    let mut brain = WorldBrain::new();
    brain
        .observe(
            "room:crossroads",
            "exit.north",
            "room:gate",
            "line:10",
            "rule",
            "midkemia",
            "midkemia",
            1,
            0.9,
            "mapper-v1",
            Sensitivity::Public,
        )
        .expect("observe");

    // New observation supersedes the old.
    brain
        .observe(
            "room:crossroads",
            "exit.north",
            "room:inn",
            "line:40",
            "rule",
            "midkemia",
            "midkemia",
            2,
            0.95,
            "mapper-v1",
            Sensitivity::Public,
        )
        .expect("observe supersede");
    assert_eq!(
        brain.current("room:crossroads", "exit.north").unwrap().value,
        "room:inn"
    );

    // User correction supersedes but preserves history.
    brain
        .correct(
            "room:crossroads",
            "exit.north",
            "room:tower",
            "the exit actually leads to the tower",
            "midkemia",
            "midkemia",
            3,
        )
        .expect("correct");
    assert_eq!(
        brain.current("room:crossroads", "exit.north").unwrap().value,
        "room:tower"
    );
    let history = brain.facts_for("room:crossroads");
    assert!(history
        .iter()
        .any(|f| f.value == "room:gate" && f.source_event == "line:10"));
    assert!(history
        .iter()
        .any(|f| f.supersession == Supersession::UserCorrected));

    // ---- 2. World Bible: continuity metadata, deterministic export. ----
    let mut bible = WorldBible::new();
    bible
        .upsert(
            "midkemia:crossroads",
            vec!["stone-gray".into(), "dusk-blue".into()],
            "cobbled",
            "dusk",
            "free-folk",
            "four-way crossroads with a weathered sign",
            "low stone walls",
            "wind over grass",
            "cautious but welcoming",
            vec!["the north road is unsafe after dark".into()],
        )
        .expect("bible upsert");
    let bible_export = bible.export_json().expect("bible export");
    assert!(bible_export.contains("midkemia:crossroads"));
    assert!(!bible_export.contains("data:image"));

    // ---- 3. Time Machine: snapshot, approval, restore. ----
    let mut view: BTreeMap<String, BTreeMap<String, String>> = BTreeMap::new();
    let mut room: BTreeMap<String, String> = BTreeMap::new();
    room.insert("exit.north".into(), "room:tower".into());
    view.insert("room:crossroads".into(), room);

    let mut tm = TimeMachine::new();
    let snap = tm.snapshot("before-battle", view.clone(), 10).expect("snapshot");
    // Restore denied until user approval.
    assert!(tm.restore(&snap.id).is_err());
    tm.approve(&snap.id).expect("approve");
    let restored = tm.restore(&snap.id).expect("restore");
    assert_eq!(restored["room:crossroads"]["exit.north"], "room:tower");

    // ---- 4. All surfaces are observers; manual gameplay preserved. ----
    assert!(!brain.can_send_command());
    assert!(!bible.can_send_command());
    assert!(!tm.can_send_command());

    println!("E2E world memory: ok");
}
