//! WireMudder EP-013 M3 snapshot export (Rust side).
//! Exports a versioned world-graph snapshot to stdout for the E2E
//! persistence flow (WM-FEAT-0168).

use wire_world_graph::{DoorStatus, Exit, ExitKind, Room, WorldGraph};

fn room(id: u32, area: u32) -> Room {
    Room {
        id,
        area,
        name: format!("room-{id}"),
        x: id as i32,
        y: 0,
        z: 0,
        identity: wire_world_graph::IdentityState::Confirmed,
        exits: Vec::new(),
    }
}

fn main() {
    let mut g = WorldGraph::new();
    for i in 1..=5 {
        g.add_room(room(i, 1)).unwrap();
    }
    for i in 1..5 {
        g.add_exit(
            i,
            Exit {
                to: i + 1,
                command: format!("n{i}"),
                kind: ExitKind::Normal,
                weight: 1,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .unwrap();
    }
    g.add_area(wire_world_graph::Area {
        id: 1,
        name: "Test Area".into(),
        zone: None,
        room_ids: [1, 2, 3, 4, 5].into_iter().collect(),
    })
    .unwrap();
    println!("{}", g.export_json().unwrap());
}
