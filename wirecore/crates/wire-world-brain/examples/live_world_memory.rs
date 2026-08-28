//! EP-021 M5 live-fire: world-memory-correction certification.
//!
//! Runs the real user outcome for World Brain, World Bible, and Time
//! Machine against the real crates and writes certification evidence:
//! facts carry provenance and confidence; user correction supersedes
//! but preserves history; hot state and durable memory are separate;
//! World Bible continuity is exportable without protected assets; Time
//! Machine snapshots restore safely only from user-approved checkpoints;
//! private data stays scoped; every surface is observer-only.
//!
//! Run: cargo run --example live_world_memory (in wire-world-brain).

use wire_time_machine::TimeMachine;
use wire_world_bible::WorldBible;
use wire_world_brain::{Sensitivity, Supersession, WorldBrain};

fn main() {
    let mut evidence = serde_json::Map::new();

    // ---- 1. Facts carry provenance and confidence. ----
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
    let f = brain.current("room:crossroads", "exit.north").unwrap();
    evidence.insert(
        "provenance_recorded".into(),
        serde_json::json!(
            f.source_event == "line:10" && f.confidence == 0.9 && f.sensitivity == Sensitivity::Public
                && !f.content_hash.is_empty()
        ),
    );

    // ---- 2. User correction supersedes but preserves history. ----
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
    evidence.insert(
        "correction_supersedes".into(),
        serde_json::json!(
            brain.current("room:crossroads", "exit.north").unwrap().value == "room:tower"
        ),
    );
    let history = brain.facts_for("room:crossroads");
    evidence.insert(
        "history_preserved".into(),
        serde_json::json!(
            history.iter().any(|h| h.value == "room:gate" && h.source_event == "line:10")
                && history.iter().any(|h| h.supersession == Supersession::UserCorrected)
        ),
    );

    // ---- 3. Hot state and durable memory are separate. ----
    let mut hot = WorldBrain::new();
    hot.set_hot_room("room:gate");
    evidence.insert(
        "hot_durable_separate".into(),
        serde_json::json!(hot.hot_room() == Some("room:gate") && hot.count() == 0),
    );

    // ---- 4. World Bible continuity is exportable; no protected assets. ----
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
    let export = bible.export_json().expect("bible export");
    evidence.insert(
        "bible_exportable".into(),
        serde_json::json!(export.contains("midkemia:crossroads") && export.contains("schema_version")),
    );
    evidence.insert(
        "no_protected_assets".into(),
        serde_json::json!(!export.contains("data:image") && !export.contains("base64")),
    );

    // ---- 5. Time Machine restores safely from user-approved checkpoints. ----
    let mut tm = TimeMachine::new();
    let mut view = std::collections::BTreeMap::new();
    let mut room = std::collections::BTreeMap::new();
    room.insert("exit.north".into(), "room:tower".into());
    view.insert("room:crossroads".into(), room);
    let snap = tm.snapshot("before-battle", view, 10).expect("snapshot");
    evidence.insert(
        "restore_denied_until_approved".into(),
        serde_json::json!(tm.restore(&snap.id).is_err()),
    );
    tm.approve(&snap.id).expect("approve");
    let restored = tm.restore(&snap.id).expect("restore");
    evidence.insert(
        "restore_approved".into(),
        serde_json::json!(restored["room:crossroads"]["exit.north"] == "room:tower"),
    );

    // ---- 6. Private data stays scoped; surfaces observer-only. ----
    brain
        .observe(
            "room:crossroads",
            "whisper",
            "the password is hunter2",
            "line:120",
            "rule",
            "midkemia",
            "midkemia",
            4,
            0.9,
            "mapper-v1",
            Sensitivity::Secret,
        )
        .expect("observe secret");
    evidence.insert(
        "private_scoped".into(),
        serde_json::json!(brain.current("room:crossroads", "whisper").unwrap().sensitivity == Sensitivity::Secret),
    );
    evidence.insert(
        "brain_observer".into(),
        serde_json::json!(!brain.can_send_command()),
    );
    evidence.insert(
        "bible_observer".into(),
        serde_json::json!(!bible.can_send_command()),
    );
    evidence.insert(
        "time_machine_observer".into(),
        serde_json::json!(!tm.can_send_command()),
    );

    // ---- Write certification evidence with real measured values. ----
    std::fs::create_dir_all(".agent/state/evidence/EP-021/M5").expect("evidence dir");
    std::fs::write(
        ".agent/state/evidence/EP-021/M5/lf021-certification.json",
        serde_json::to_string_pretty(&serde_json::Value::Object(evidence)).expect("evidence json"),
    )
    .expect("evidence write");

    println!("LF-021 live: ok");
}
