//! WireMudder EP-013 M4 routing benchmark (Rust side).
//! Measures worst-case deterministic Dijkstra routing on a large graph
//! and emits JSON evidence (hardware, workload, distributions,
//! thresholds). Budget: each route under 10 ms (SPEC-004).

use std::time::Instant;
use wire_world_graph::{DoorStatus, Exit, ExitKind, Room, WorldGraph};

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
    // 10,000-room grid graph (100x100) with two exits per room.
    let size = 100u32;
    let mut g = WorldGraph::new();
    for y in 0..size {
        for x in 0..size {
            let id = y * size + x + 1;
            g.add_room(room(id)).unwrap();
        }
    }
    for y in 0..size {
        for x in 0..size {
            let id = y * size + x + 1;
            if x + 1 < size {
                g.add_exit(
                    id,
                    Exit {
                        to: id + 1,
                        command: "east".into(),
                        kind: ExitKind::Normal,
                        weight: 1,
                        door: DoorStatus::None,
                        timed: None,
                    },
                )
                .unwrap();
            }
            if y + 1 < size {
                g.add_exit(
                    id,
                    Exit {
                        to: id + size,
                        command: "south".into(),
                        kind: ExitKind::Normal,
                        weight: 1,
                        door: DoorStatus::None,
                        timed: None,
                    },
                )
                .unwrap();
            }
        }
    }

    // Corner-to-corner routes (worst case on the grid).
    let routes = [
        (1u32, size * size),
        (1u32, size * size - size + 1),
        (1u32, size * size / 2),
    ];
    let mut samples_ms: Vec<f64> = Vec::new();
    for (from, to) in routes {
        let t0 = Instant::now();
        let r = g.route(from, to, None, false).unwrap();
        let ms = t0.elapsed().as_secs_f64() * 1000.0;
        samples_ms.push(ms);
        assert!(r.nodes.len() > 1);
    }
    samples_ms.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let p50 = samples_ms[samples_ms.len() / 2];
    let p95 = samples_ms[(samples_ms.len() as f64 * 0.95) as usize];
    let budget_ms = 10.0;
    let ok = p95 < budget_ms;

    let ev = serde_json::json!({
        "fixture": "mapper-route-bench",
        "rooms": size * size,
        "routes": routes.len(),
        "distributions_ms": {"p50": p50, "p95": p95},
        "budget_ms": budget_ms,
        "ok": ok,
        "node": "EP-013",
        "milestone": "M4",
    });
    println!("{}", ev);
    if !ok {
        std::process::exit(1);
    }
}
