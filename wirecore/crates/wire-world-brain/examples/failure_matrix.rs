//! EP-021 M4: failure matrix for the world-memory stack.
//!
//! Forces real failures through the real crates (wire-world-brain,
//! wire-world-bible, wire-time-machine): malformed input, not-found,
//! resource exhaustion, oversized tokens, restore-without-approval,
//! and recovery. Asserts typed errors (SPEC-025) and preserved manual
//! gameplay (observer-only surfaces).
//!
//! Run: cargo run --example failure_matrix

use std::collections::BTreeMap;

use wire_time_machine::TimeMachine;
use wire_world_bible::WorldBible;
use wire_world_brain::{Sensitivity, WorldBrain};

fn main() {
    // --- World Brain forced failures ---
    let mut brain = WorldBrain::new();

    // Malformed input rejected.
    assert!(brain
        .observe("", "a", "v", "s", "r", "p", "w", 1, 0.5, "v", Sensitivity::Public)
        .is_err());
    assert!(brain
        .observe("s", "a", "", "s", "r", "p", "w", 1, 0.5, "v", Sensitivity::Public)
        .is_err());
    assert!(brain
        .observe("s", "a", "v", "s", "r", "p", "w", 1, 1.5, "v", Sensitivity::Public)
        .is_err());

    // Correction of a missing fact fails closed.
    assert!(brain.correct("room:missing", "exit.north", "x", "n", "p", "w", 1).is_err());

    // Recovery: after rejections, valid observation works.
    brain
        .observe(
            "room:crossroads", "exit.north", "room:gate", "line:10", "rule",
            "midkemia", "midkemia", 1, 0.9, "mapper-v1", Sensitivity::Public,
        )
        .unwrap();
    assert_eq!(brain.count(), 1);

    // --- World Bible forced failures ---
    let mut bible = WorldBible::new();
    assert!(bible.upsert("", vec![], "t", "d", "f", "s", "a", "r", "t", vec![]).is_err());
    let big = "x".repeat(2048);
    assert!(bible.upsert("r", vec![big], "t", "d", "f", "s", "a", "r", "t", vec![]).is_err());

    // Recovery.
    bible.upsert("midkemia:gate", vec!["gray".into()], "cobbled", "dim", "guard", "gatehouse", "stone", "echo", "wary", vec![]).unwrap();
    assert_eq!(bible.count(), 1);

    // --- Time Machine forced failures ---
    let mut tm = TimeMachine::new();
    let mut view: BTreeMap<String, BTreeMap<String, String>> = BTreeMap::new();
    let mut room: BTreeMap<String, String> = BTreeMap::new();
    room.insert("exit.north".into(), "room:gate".into());
    view.insert("room:crossroads".into(), room);

    let snap = tm.snapshot("checkpoint-1", view, 1).unwrap();

    // Restore without approval fails closed (SPEC-012-R09).
    assert!(tm.restore(&snap.id).is_err());

    // Malformed snapshot label rejected.
    assert!(tm.snapshot("", BTreeMap::new(), 2).is_err());

    // Approve then restore succeeds; durable state untouched.
    tm.approve(&snap.id).unwrap();
    let restored = tm.restore(&snap.id).unwrap();
    assert_eq!(restored["room:crossroads"]["exit.north"], "room:gate");

    // --- Manual gameplay preserved: observer-only surfaces ---
    assert!(!brain.can_send_command());
    assert!(!bible.can_send_command());
    assert!(!tm.can_send_command());

    println!("failure matrix: ok");
}
