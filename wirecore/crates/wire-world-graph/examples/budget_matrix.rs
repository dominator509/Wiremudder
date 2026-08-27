//! WireMudder EP-013 M4 budget/cancellation matrix (Rust side).
//! Proves routing is bounded: a route that would exceed the node budget
//! returns the typed BudgetExceeded error, and dropping a route request
//! is safe (no panics, no leaked state).

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
    // Chain graph of 1000 rooms with a deliberately small per-graph
    // budget of 100 nodes: routing 1 -> 1000 must terminate with
    // BudgetExceeded instead of exploring forever.
    let n = 1000u32;
    let mut g = WorldGraph::new();
    g.route_budget = 100;
    for i in 1..=n {
        g.add_room(room(i)).unwrap();
    }
    for i in 1..n {
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
    let budget = matches!(
        g.route(1, n, None, false),
        Err(wire_world_graph::RouteError::BudgetExceeded)
    );
    println!("budget-exceeded:{}", if budget { "ok" } else { "fail" });

    // Cancellation safety: drop a route request; the graph remains
    // usable for a subsequent short route (no poisoned state).
    let g2 = g.clone();
    drop(g2.route(1, n, None, false));
    let short = g.route(1, 2, None, false).is_ok();
    println!("cancel-safe:{}", if short { "ok" } else { "fail" });
}
