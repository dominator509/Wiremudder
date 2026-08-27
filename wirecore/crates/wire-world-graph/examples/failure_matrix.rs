//! WireMudder EP-013 M4 failure matrix (Rust side).
//! Prints typed-failure outcomes for resource exhaustion and malformed
//! input. Real controlled failures, no mocks.

use wire_world_graph::{
    DoorStatus, Exit, ExitKind, Room, TimedWindow, WorldGraph, MAX_EXITS_PER_ROOM,
    MAX_ROOMS,
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
    // Room limit.
    let mut g = WorldGraph::new();
    let mut room_limit_ok = false;
    for i in 0..(MAX_ROOMS as u32) {
        if g.add_room(room(i)).is_err() {
            break;
        }
    }
    room_limit_ok = g.add_room(room(MAX_ROOMS as u32 + 1)).is_err();
    println!("room-limit:{}", if room_limit_ok { "ok" } else { "fail" });

    // Exit limit + duplicate + unknown room.
    let mut h = WorldGraph::new();
    h.add_room(room(1)).unwrap();
    h.add_room(room(2)).unwrap();
    let mut exit_limit_ok = false;
    for i in 0..MAX_EXITS_PER_ROOM {
        if h.add_exit(
            1,
            Exit {
                to: 2,
                command: format!("cmd{i}"),
                kind: ExitKind::Normal,
                weight: 1,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .is_err()
        {
            break;
        }
    }
    exit_limit_ok = h
        .add_exit(
            1,
            Exit {
                to: 2,
                command: "overflow".into(),
                kind: ExitKind::Normal,
                weight: 1,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .is_err();
    println!("exit-limit:{}", if exit_limit_ok { "ok" } else { "fail" });

    let dup = h
        .add_exit(
            1,
            Exit {
                to: 2,
                command: "cmd0".into(),
                kind: ExitKind::Normal,
                weight: 1,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .is_err();
    println!("duplicate-exit:{}", if dup { "ok" } else { "fail" });

    let unknown = h
        .add_exit(
            999,
            Exit {
                to: 2,
                command: "x".into(),
                kind: ExitKind::Normal,
                weight: 1,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .is_err();
    println!("unknown-room:{}", if unknown { "ok" } else { "fail" });

    // Malformed snapshot and bad version.
    let mut s = WorldGraph::new();
    let bad_json = s.import_json("not json").is_err();
    println!("bad-snapshot:{}", if bad_json { "ok" } else { "fail" });
    let bad_ver = s.import_json(r#"{"schema_version": 999, "rooms": {}}"#).is_err();
    println!("bad-version:{}", if bad_ver { "ok" } else { "fail" });

    // Invalid timed window.
    let mut t = WorldGraph::new();
    t.add_room(room(1)).unwrap();
    t.add_room(room(2)).unwrap();
    let bad_timed = t
        .add_exit(
            1,
            Exit {
                to: 2,
                command: "gate".into(),
                kind: ExitKind::Normal,
                weight: 1,
                door: DoorStatus::None,
                timed: Some(TimedWindow {
                    start_minute: 1500,
                    end_minute: 1600,
                }),
            },
        )
        .is_err();
    println!("invalid-timed:{}", if bad_timed { "ok" } else { "fail" });

    // No-path typed error.
    let np = matches!(t.route(2, 1, None, false), Err(_));
    println!("no-path:{}", if np { "ok" } else { "fail" });
}
