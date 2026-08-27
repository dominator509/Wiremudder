//! WireMudder EP-013 M3 parity oracle (Rust side).
//!
//! Prints a deterministic matrix of world-graph decisions that the C++
//! mapper boundary must reproduce exactly (cross-implementation parity,
//! mirroring the EP-006 egress policy oracle pattern).

use wire_world_graph::{
    DoorStatus, Exit, ExitKind, IdentityState, Room, TimedWindow, WorldGraph,
};

fn room(id: u32, area: u32) -> Room {
    Room {
        id,
        area,
        name: format!("room-{id}"),
        x: id as i32,
        y: 0,
        z: 0,
        identity: IdentityState::Confirmed,
        exits: Vec::new(),
    }
}

fn main() {
    // 1. Line graph 1..5 with weight-1 exits.
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
    let r = g.route(1, 5, None, false).unwrap();
    println!("route:1->5:{}:{}", r.total_weight, r.commands.join(","));

    // 2. One-way not reversible.
    let mut ow = WorldGraph::new();
    ow.add_room(room(1, 1)).unwrap();
    ow.add_room(room(2, 1)).unwrap();
    ow.add_exit(
        1,
        Exit {
            to: 2,
            command: "east".into(),
            kind: ExitKind::OneWay,
            weight: 1,
            door: DoorStatus::None,
            timed: None,
        },
    )
    .unwrap();
    println!("one-way:1->2:{}", ow.route(1, 2, None, false).is_ok());
    println!(
        "one-way:2->1:{}",
        matches!(ow.route(2, 1, None, false), Err(_))
    );

    // 3. Locked exit blocks.
    let mut lk = WorldGraph::new();
    lk.add_room(room(1, 1)).unwrap();
    lk.add_room(room(2, 1)).unwrap();
    lk.add_exit(
        1,
        Exit {
            to: 2,
            command: "east".into(),
            kind: ExitKind::Locked,
            weight: 1,
            door: DoorStatus::None,
            timed: None,
        },
    )
    .unwrap();
    println!(
        "locked:1->2:{}",
        matches!(lk.route(1, 2, None, false), Err(_))
    );

    // 4. Hidden exit requires opt-in.
    let mut hd = WorldGraph::new();
    hd.add_room(room(1, 1)).unwrap();
    hd.add_room(room(2, 1)).unwrap();
    hd.add_exit(
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
    println!(
        "hidden:1->2:{}",
        matches!(hd.route(1, 2, None, false), Err(_))
    );
    println!("hidden-optin:1->2:{}", hd.route(1, 2, None, true).is_ok());

    // 5. Timed window.
    let mut tm = WorldGraph::new();
    tm.add_room(room(1, 1)).unwrap();
    tm.add_room(room(2, 1)).unwrap();
    tm.add_exit(
        1,
        Exit {
            to: 2,
            command: "gate".into(),
            kind: ExitKind::Normal,
            weight: 1,
            door: DoorStatus::None,
            timed: Some(TimedWindow {
                start_minute: 600,
                end_minute: 660,
            }),
        },
    )
    .unwrap();
    println!("timed-open:1->2:{}", tm.route(1, 2, Some(610), false).is_ok());
    println!(
        "timed-closed:1->2:{}",
        matches!(tm.route(1, 2, Some(100), false), Err(_))
    );
    println!(
        "timed-noctx:1->2:{}",
        matches!(tm.route(1, 2, None, false), Err(_))
    );

    // 6. Weighted routing prefers cheaper path.
    let mut wg = WorldGraph::new();
    wg.add_room(room(1, 1)).unwrap();
    wg.add_room(room(2, 1)).unwrap();
    wg.add_room(room(3, 1)).unwrap();
    wg.add_exit(
        1,
        Exit {
            to: 3,
            command: "east".into(),
            kind: ExitKind::Normal,
            weight: 10,
            door: DoorStatus::None,
            timed: None,
        },
    )
    .unwrap();
    wg.add_exit(
        1,
        Exit {
            to: 2,
            command: "ne".into(),
            kind: ExitKind::Normal,
            weight: 2,
            door: DoorStatus::None,
            timed: None,
        },
    )
    .unwrap();
    wg.add_exit(
        2,
        Exit {
            to: 3,
            command: "se".into(),
            kind: ExitKind::Normal,
            weight: 2,
            door: DoorStatus::None,
            timed: None,
        },
    )
    .unwrap();
    let wr = wg.route(1, 3, None, false).unwrap();
    println!(
        "weighted:1->3:{}:{}",
        wr.total_weight,
        wr.nodes.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(",")
    );

    // 7. Zone clustering.
    let mut zg = WorldGraph::new();
    zg.add_area(wire_world_graph::Area {
        id: 1,
        name: "A".into(),
        zone: None,
        room_ids: [1, 2].into_iter().collect(),
    })
    .unwrap();
    zg.add_area(wire_world_graph::Area {
        id: 2,
        name: "B".into(),
        zone: None,
        room_ids: [3].into_iter().collect(),
    })
    .unwrap();
    zg.add_zone(wire_world_graph::Zone {
        id: 1,
        name: "Z".into(),
        area_ids: Default::default(),
    })
    .unwrap();
    zg.assign_area_to_zone(1, 1).unwrap();
    zg.assign_area_to_zone(2, 1).unwrap();
    println!(
        "zone:1:{}",
        zg.rooms_in_zone(1)
            .iter()
            .map(|n| n.to_string())
            .collect::<Vec<_>>()
            .join(",")
    );

    // 8. Import/export round-trip preserves routes.
    let json = g.export_json().unwrap();
    let mut g2 = WorldGraph::new();
    g2.import_json(&json).unwrap();
    let r2 = g2.route(1, 5, None, false).unwrap();
    println!("roundtrip:{}", r2.total_weight == 4 && r2.nodes == vec![1, 2, 3, 4, 5]);

    // 9. Facts provenance + correction supersession.
    let mut fg = WorldGraph::new();
    let fid = fg.insert_fact(
        "room-enter#42",
        1000,
        "profile:dom",
        0.9,
        wire_world_graph::Sensitivity::Private,
        "rule-v1",
        serde_json::json!({"room": 1}),
    );
    fg.apply_correction(fid, 2000, serde_json::json!({"room": 7}), "user said room 7")
        .unwrap();
    println!("facts:{}:{}:{}", fid, fg.active_facts().len(), fg.corrections.len());
}
