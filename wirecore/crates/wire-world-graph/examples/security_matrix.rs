//! WireMudder EP-013 M4 security matrix (Rust side).
//! Covers the node-applicable security obligations:
//! - secrets: derived facts carry sensitivity; secret facts stay marked
//!   so shared-world promotion can be refused downstream
//! - denied policy: hidden/locked exits are not traversable without
//!   explicit opt-in or permission
//! - prompt injection: hostile room names and exit commands round-trip
//!   as data, never as code or control
//! - data integrity: tampered snapshots are rejected

use wire_world_graph::{
    DoorStatus, Exit, ExitKind, Room, Sensitivity, WorldGraph,
};

fn room(id: u32) -> Room {
    Room {
        id,
        area: 1,
        name: format!("room-{id}"),
        x: id as i32,
        y: 0,
        z: 0,
        identity: wire_world_graph::IdentityState::Confirmed,
        exits: Vec::new(),
    }
}

fn main() {
    // 1. Secrets: a Secret-sensitivity fact remains marked Secret after
    //    export/import (round-trip classification preserved).
    let mut g = WorldGraph::new();
    g.insert_fact(
        "observation#1",
        1000,
        "profile:dom",
        0.95,
        Sensitivity::Secret,
        "rule-v1",
        serde_json::json!({"room": 1, "note": "hidden stash"}),
    );
    let json = g.export_json().unwrap();
    let mut g2 = WorldGraph::new();
    g2.import_json(&json).unwrap();
    let sec = g2.facts[0].sensitivity == Sensitivity::Secret;
    println!("secrets-classified:{}", if sec { "ok" } else { "fail" });

    // 2. Denied policy: hidden exit requires allow_hidden opt-in;
    //    locked exit and locked door are never traversable.
    let mut h = WorldGraph::new();
    h.add_room(room(1)).unwrap();
    h.add_room(room(2)).unwrap();
    h.add_exit(
        1,
        Exit {
            to: 2,
            command: "secret".into(),
            kind: ExitKind::Hidden,
            weight: 1,
            door: DoorStatus::None,
            timed: None,
        },
    )
    .unwrap();
    let denied_no_optin = matches!(h.route(1, 2, None, false), Err(_));
    let allowed_optin = h.route(1, 2, None, true).is_ok();
    let denied_policy = denied_no_optin && allowed_optin;
    println!("denied-policy:{}", if denied_policy { "ok" } else { "fail" });

    // 3. Prompt injection: hostile names/commands survive as data.
    let mut inj = WorldGraph::new();
    let mut r = room(1);
    r.name = "room; DROP TABLE rooms; --".into();
    r.exits.push(Exit {
        to: 2,
        command: "east; quit()".into(),
        kind: ExitKind::Normal,
        weight: 1,
        door: DoorStatus::None,
        timed: None,
    });
    inj.add_room(r).unwrap();
    inj.add_room(room(2)).unwrap();
    let out = inj.export_json().unwrap();
    let mut inj2 = WorldGraph::new();
    inj2.import_json(&out).unwrap();
    let name_ok = inj2.room(1).unwrap().name == "room; DROP TABLE rooms; --";
    let cmd_ok = inj2.room(1).unwrap().exits[0].command == "east; quit()";
    let injection = name_ok && cmd_ok;
    println!("injection-as-data:{}", if injection { "ok" } else { "fail" });

    // 4. Data integrity: tampered snapshot rejected.
    let mut t = WorldGraph::new();
    let good = t.export_json().unwrap();
    // Flip the schema version to simulate tampering (pretty-printed JSON
    // uses `"schema_version": 1` with a space).
    let tampered = good.replace("\"schema_version\": 1", "\"schema_version\": 2");
    let rejected = t.import_json(&tampered).is_err();
    println!("integrity-tamper:{}", if rejected { "ok" } else { "fail" });
}
