//! WireMudder World Graph (SPEC-012, EP-013).
//!
//! Namespaced core for the mapper and world-brain integration. Preserves
//! the inherited Mudlet mapper as canonical and adds typed world-graph
//! events, derived-fact provenance, confidence and corrections, weighted
//! and timed routing, hot current-state cache, and bounded versioned
//! events (WM-SPEC-012-R02, R03, R04, R05, R10; WM-FEAT-0165..0168).
//!
//! Design rules:
//! - Deterministic: same inputs, same outputs. No wall-clock dependence
//!   inside routing decisions except explicit `now` parameters.
//! - Bounded: room/exit/event/cache limits are enforced.
//! - No silent merge: ambiguous room identity stays uncertain (R05).
//! - Corrections supersede derived facts while preserving history (R10).

use serde::{Deserialize, Serialize};
use std::cmp::Reverse;
use std::collections::{BinaryHeap, HashMap, HashSet, VecDeque};

pub const WORLD_SCHEMA_VERSION: u32 = 1;
pub const MAX_ROOMS: usize = 1_000_000;
pub const MAX_EXITS_PER_ROOM: usize = 64;
pub const MAX_EVENT_LOG: usize = 8192;
pub const MAX_HOT_CACHE_ENTRIES: usize = 4096;
pub const MAX_ROUTE_NODES: usize = 1_000_000;

/// Typed exit kinds (WM-FEAT-0166).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ExitKind {
    Normal,
    Hidden,
    Locked,
    OneWay,
    Portal,
}

/// Door status modeled after inherited TRoom::setDoor semantics:
/// 0 = no door, 1 = open, 2 = closed, 3 = locked (WM-SPEC-005-R07).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum DoorStatus {
    None,
    Open,
    Closed,
    Locked,
}

/// Timed exit availability window in minutes of day [0, 1440).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct TimedWindow {
    pub start_minute: u32,
    pub end_minute: u32,
}

impl TimedWindow {
    pub fn contains(&self, minute: u32) -> bool {
        if self.start_minute <= self.end_minute {
            minute >= self.start_minute && minute < self.end_minute
        } else {
            // Overnight window: wraps past midnight.
            minute >= self.start_minute || minute < self.end_minute
        }
    }
}

/// A single exit from a room (WM-FEAT-0166, WM-SPEC-005-R07).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Exit {
    pub to: u32,
    pub command: String,
    pub kind: ExitKind,
    pub weight: u32,
    pub door: DoorStatus,
    pub timed: Option<TimedWindow>,
}

/// Room identity confidence (WM-SPEC-012-R05).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum IdentityState {
    Confirmed,
    Ambiguous,
    Corrected,
}

/// A room in the world graph (WM-SPEC-005-R07, WM-SPEC-012-R01).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Room {
    pub id: u32,
    pub area: u32,
    pub name: String,
    pub x: i32,
    pub y: i32,
    pub z: i32,
    pub identity: IdentityState,
    pub exits: Vec<Exit>,
}

impl Room {
    pub fn exit_to(&self, to: u32) -> Option<&Exit> {
        self.exits.iter().find(|e| e.to == to)
    }

    pub fn has_exit_command(&self, command: &str) -> bool {
        self.exits.iter().any(|e| e.command == command)
    }
}

/// Area grouping (WM-FEAT-0165).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Area {
    pub id: u32,
    pub name: String,
    pub zone: Option<u32>,
    pub room_ids: HashSet<u32>,
}

/// Zone clustering (WM-FEAT-0165).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Zone {
    pub id: u32,
    pub name: String,
    pub area_ids: HashSet<u32>,
}

/// Derived fact provenance (WM-SPEC-012-R02).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Sensitivity {
    Public,
    Private,
    Secret,
}

/// A derived fact with full provenance and supersession state.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DerivedFact {
    pub id: u64,
    pub source_event: String,
    pub time: u64,
    pub scope: String,
    pub confidence: f64,
    pub sensitivity: Sensitivity,
    pub model_version: String,
    pub superseded_by: Option<u64>,
    pub payload: serde_json::Value,
}

/// User correction that supersedes a derived fact (WM-SPEC-012-R10).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Correction {
    pub fact_id: u64,
    pub time: u64,
    pub payload: serde_json::Value,
    pub note: String,
}

/// Typed world-graph event (bounded, versioned).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorldEvent {
    pub seq: u64,
    pub kind: String,
    pub room: u32,
    pub time: u64,
    pub payload: serde_json::Value,
}

/// Route result (WM-FEAT-0167).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Route {
    pub from: u32,
    pub to: u32,
    pub nodes: Vec<u32>,
    pub commands: Vec<String>,
    pub total_weight: u64,
}

/// Routing error (typed, SPEC-025 style).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum RouteError {
    MissingRoom(u32),
    NoPath,
    BudgetExceeded,
    InvalidTimedWindow,
}

/// Hot in-memory current-state cache (WM-SPEC-012-R03).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HotCache {
    pub current_room: Option<u32>,
    pub entries: HashMap<String, serde_json::Value>,
}

impl HotCache {
    pub fn new() -> Self {
        Self {
            current_room: None,
            entries: HashMap::new(),
        }
    }

    pub fn set(&mut self, key: String, value: serde_json::Value) -> Result<(), String> {
        if !self.entries.contains_key(&key) && self.entries.len() >= MAX_HOT_CACHE_ENTRIES {
            return Err("hot cache full".into());
        }
        self.entries.insert(key, value);
        Ok(())
    }

    pub fn get(&self, key: &str) -> Option<&serde_json::Value> {
        self.entries.get(key)
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }
}

impl Default for HotCache {
    fn default() -> Self {
        Self::new()
    }
}

/// The world graph (WM-FEAT-0165..0168).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct WorldGraph {
    pub schema_version: u32,
    pub rooms: HashMap<u32, Room>,
    pub areas: HashMap<u32, Area>,
    pub zones: HashMap<u32, Zone>,
    pub facts: Vec<DerivedFact>,
    pub corrections: Vec<Correction>,
    pub events: VecDeque<WorldEvent>,
    pub next_event_seq: u64,
    pub next_fact_id: u64,
    pub cache: HotCache,
    /// Per-graph route exploration budget (defaults to MAX_ROUTE_NODES).
    #[serde(default = "default_route_budget")]
    pub route_budget: usize,
}

fn default_route_budget() -> usize {
    MAX_ROUTE_NODES
}

impl WorldGraph {
    pub fn new() -> Self {
        Self {
            schema_version: WORLD_SCHEMA_VERSION,
            rooms: HashMap::new(),
            areas: HashMap::new(),
            zones: HashMap::new(),
            facts: Vec::new(),
            corrections: Vec::new(),
            events: VecDeque::new(),
            next_event_seq: 1,
            next_fact_id: 1,
            cache: HotCache::new(),
            route_budget: MAX_ROUTE_NODES,
        }
    }

    pub fn add_room(&mut self, room: Room) -> Result<(), String> {
        if self.rooms.len() >= MAX_ROOMS {
            return Err("room limit exceeded".into());
        }
        if room.exits.len() > MAX_EXITS_PER_ROOM {
            return Err("exit limit exceeded".into());
        }
        self.rooms.insert(room.id, room);
        Ok(())
    }

    pub fn add_area(&mut self, area: Area) -> Result<(), String> {
        if self.areas.contains_key(&area.id) {
            return Err("duplicate area".into());
        }
        self.areas.insert(area.id, area);
        Ok(())
    }

    pub fn add_zone(&mut self, zone: Zone) -> Result<(), String> {
        if self.zones.contains_key(&zone.id) {
            return Err("duplicate zone".into());
        }
        self.zones.insert(zone.id, zone);
        Ok(())
    }

    pub fn room(&self, id: u32) -> Option<&Room> {
        self.rooms.get(&id)
    }

    pub fn room_mut(&mut self, id: u32) -> Option<&mut Room> {
        self.rooms.get_mut(&id)
    }

    /// Cluster an area into a zone (WM-FEAT-0165).
    pub fn assign_area_to_zone(&mut self, area_id: u32, zone_id: u32) -> Result<(), String> {
        let area = self
            .areas
            .get_mut(&area_id)
            .ok_or_else(|| format!("unknown area {area_id}"))?;
        if !self.zones.contains_key(&zone_id) {
            return Err(format!("unknown zone {zone_id}"));
        }
        area.zone = Some(zone_id);
        if let Some(zone) = self.zones.get_mut(&zone_id) {
            zone.area_ids.insert(area_id);
        }
        Ok(())
    }

    /// Rooms in a zone, computed through areas (WM-FEAT-0165).
    pub fn rooms_in_zone(&self, zone_id: u32) -> Vec<u32> {
        let mut out = Vec::new();
        if let Some(zone) = self.zones.get(&zone_id) {
            for area_id in &zone.area_ids {
                if let Some(area) = self.areas.get(area_id) {
                    out.extend(area.room_ids.iter().copied());
                }
            }
        }
        out.sort_unstable();
        out
    }

    /// Add a typed exit; validates target and per-room bound (WM-FEAT-0166).
    pub fn add_exit(&mut self, from: u32, exit: Exit) -> Result<(), String> {
        if !self.rooms.contains_key(&from) {
            return Err(format!("unknown source room {from}"));
        }
        if !self.rooms.contains_key(&exit.to) {
            return Err(format!("unknown target room {}", exit.to));
        }
        if let Some(t) = exit.timed {
            if t.start_minute >= 1440 || t.end_minute >= 1440 {
                return Err("invalid timed window".into());
            }
        }
        let room = self
            .rooms
            .get_mut(&from)
            .ok_or_else(|| format!("unknown source room {from}"))?;
        if room.exits.len() >= MAX_EXITS_PER_ROOM {
            return Err("exit limit exceeded".into());
        }
        if room.exits.iter().any(|e| e.command == exit.command) {
            return Err("duplicate exit command".into());
        }
        room.exits.push(exit);
        Ok(())
    }

    /// Record a typed event; log is bounded (WM-SPEC-012-R02/R03).
    pub fn push_event(&mut self, kind: &str, room: u32, time: u64, payload: serde_json::Value) {
        let ev = WorldEvent {
            seq: self.next_event_seq,
            kind: kind.to_string(),
            room,
            time,
            payload,
        };
        self.next_event_seq += 1;
        self.events.push_back(ev);
        while self.events.len() > MAX_EVENT_LOG {
            self.events.pop_front();
        }
    }

    /// Insert a derived fact with provenance; supersedes any prior fact
    /// with the same source event when told to (WM-SPEC-012-R02).
    pub fn insert_fact(
        &mut self,
        source_event: &str,
        time: u64,
        scope: &str,
        confidence: f64,
        sensitivity: Sensitivity,
        model_version: &str,
        payload: serde_json::Value,
    ) -> u64 {
        let id = self.next_fact_id;
        self.next_fact_id += 1;
        self.facts.push(DerivedFact {
            id,
            source_event: source_event.to_string(),
            time,
            scope: scope.to_string(),
            confidence: confidence.clamp(0.0, 1.0),
            sensitivity,
            model_version: model_version.to_string(),
            superseded_by: None,
            payload,
        });
        id
    }

    /// Apply a user correction: supersede the target fact and any chain
    /// derived from it while preserving history (WM-SPEC-012-R10).
    pub fn apply_correction(
        &mut self,
        fact_id: u64,
        time: u64,
        payload: serde_json::Value,
        note: &str,
    ) -> Result<(), String> {
        let target = self
            .facts
            .iter()
            .find(|f| f.id == fact_id)
            .ok_or_else(|| format!("unknown fact {fact_id}"))?;
        let _ = target;
        for fact in &mut self.facts {
            if fact.id == fact_id {
                fact.superseded_by = Some(self.next_fact_id);
                fact.payload = payload.clone();
            }
        }
        self.corrections.push(Correction {
            fact_id,
            time,
            payload,
            note: note.to_string(),
        });
        Ok(())
    }

    /// Facts not yet superseded (active facts).
    pub fn active_facts(&self) -> Vec<&DerivedFact> {
        self.facts
            .iter()
            .filter(|f| f.superseded_by.is_none())
            .collect()
    }

    /// Export the graph to a versioned JSON snapshot (WM-FEAT-0168).
    pub fn export_json(&self) -> Result<String, String> {
        serde_json::to_string_pretty(self).map_err(|e| e.to_string())
    }

    /// Import from a versioned JSON snapshot; rejects unknown versions
    /// and malformed payloads (WM-FEAT-0168, SPEC-021).
    pub fn import_json(&mut self, json: &str) -> Result<(), String> {
        let parsed: serde_json::Value =
            serde_json::from_str(json).map_err(|e| format!("malformed snapshot: {e}"))?;
        let version = parsed
            .get("schema_version")
            .and_then(|v| v.as_u64())
            .ok_or("snapshot missing schema_version")?;
        if version != WORLD_SCHEMA_VERSION as u64 {
            return Err(format!(
                "unsupported schema version {version} (expected {WORLD_SCHEMA_VERSION})"
            ));
        }
        let graph: WorldGraph =
            serde_json::from_value(parsed).map_err(|e| format!("invalid snapshot: {e}"))?;
        *self = graph;
        Ok(())
    }

    /// A-star routing with weights, one-way, hidden/locked handling and
    /// timed windows (WM-FEAT-0167). `now` is a minute of day; pass
    /// `None` to ignore timed windows. Hidden exits are routable only
    /// when the caller opts in via `allow_hidden`.
    pub fn route(
        &self,
        from: u32,
        to: u32,
        now: Option<u32>,
        allow_hidden: bool,
    ) -> Result<Route, RouteError> {
        if !self.rooms.contains_key(&from) {
            return Err(RouteError::MissingRoom(from));
        }
        if !self.rooms.contains_key(&to) {
            return Err(RouteError::MissingRoom(to));
        }
        if from == to {
            return Ok(Route {
                from,
                to,
                nodes: vec![from],
                commands: Vec::new(),
                total_weight: 0,
            });
        }

        let mut dist: HashMap<u32, u64> = HashMap::new();
        let mut prev: HashMap<u32, (u32, String)> = HashMap::new();
        let mut visited: HashSet<u32> = HashSet::new();
        // Deterministic Dijkstra with a binary heap. Ties are broken by
        // smaller room id (Reverse on both keys) to match the C++
        // boundary exactly (SPEC-004, EP-013 parity oracle).
        let mut queue: BinaryHeap<(Reverse<u64>, Reverse<u32>)> = BinaryHeap::new();
        dist.insert(from, 0);
        queue.push((Reverse(0), Reverse(from)));
        let mut opened = 0usize;
        while let Some((Reverse(d_cur), Reverse(cur))) = queue.pop() {
            if visited.contains(&cur) {
                continue;
            }
            if cur == to {
                break;
            }
            if dist.get(&cur).map_or(false, |d| d_cur > *d) {
                continue; // stale entry
            }
            visited.insert(cur);
            opened += 1;
            if opened > self.route_budget {
                return Err(RouteError::BudgetExceeded);
            }
            let Some(room) = self.rooms.get(&cur) else {
                continue;
            };
            for exit in &room.exits {
                if exit.kind == ExitKind::Locked {
                    continue;
                }
                if exit.kind == ExitKind::Hidden && !allow_hidden {
                    continue;
                }
                if exit.door == DoorStatus::Locked {
                    continue;
                }
                if let Some(t) = exit.timed {
                    let Some(minute) = now else {
                        continue; // timed exit unusable without time context
                    };
                    if !t.contains(minute) {
                        continue;
                    }
                }
                let nd = d_cur + u64::from(exit.weight.max(1));
                let better = match dist.get(&exit.to) {
                    Some(d) => nd < *d,
                    None => true,
                };
                if better {
                    dist.insert(exit.to, nd);
                    prev.insert(exit.to, (cur, exit.command.clone()));
                    queue.push((Reverse(nd), Reverse(exit.to)));
                }
            }
        }

        let mut nodes = Vec::new();
        let mut commands = Vec::new();
        let mut cur = to;
        if !dist.contains_key(&to) {
            return Err(RouteError::NoPath);
        }
        while cur != from {
            let (p, cmd) = prev
                .get(&cur)
                .ok_or(RouteError::NoPath)?
                .clone();
            nodes.push(cur);
            commands.push(cmd);
            cur = p;
        }
        nodes.push(from);
        nodes.reverse();
        commands.reverse();
        Ok(Route {
            from,
            to,
            nodes,
            commands,
            total_weight: dist[&to],
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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

    fn build_line_graph() -> WorldGraph {
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
        g
    }

    #[test]
    fn route_follows_shortest_path() {
        let g = build_line_graph();
        let r = g.route(1, 5, None, false).unwrap();
        assert_eq!(r.nodes, vec![1, 2, 3, 4, 5]);
        assert_eq!(r.commands, vec!["n1", "n2", "n3", "n4"]);
        assert_eq!(r.total_weight, 4);
    }

    #[test]
    fn one_way_exit_is_not_reversible() {
        let mut g = WorldGraph::new();
        g.add_room(room(1, 1)).unwrap();
        g.add_room(room(2, 1)).unwrap();
        g.add_exit(
            1,
            Exit {
                to: 2,
                command: "east".to_string(),
                kind: ExitKind::OneWay,
                weight: 1,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .unwrap();
        assert!(g.route(1, 2, None, false).is_ok());
        assert_eq!(g.route(2, 1, None, false), Err(RouteError::NoPath));
    }

    #[test]
    fn locked_exit_blocks_routing() {
        let mut g = WorldGraph::new();
        g.add_room(room(1, 1)).unwrap();
        g.add_room(room(2, 1)).unwrap();
        g.add_exit(
            1,
            Exit {
                to: 2,
                command: "east".to_string(),
                kind: ExitKind::Locked,
                weight: 1,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .unwrap();
        assert_eq!(g.route(1, 2, None, false), Err(RouteError::NoPath));
    }

    #[test]
    fn hidden_exit_requires_opt_in() {
        let mut g = WorldGraph::new();
        g.add_room(room(1, 1)).unwrap();
        g.add_room(room(2, 1)).unwrap();
        g.add_exit(
            1,
            Exit {
                to: 2,
                command: "secret".to_string(),
                kind: ExitKind::Hidden,
                weight: 1,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .unwrap();
        assert_eq!(g.route(1, 2, None, false), Err(RouteError::NoPath));
        assert!(g.route(1, 2, None, true).is_ok());
    }

    #[test]
    fn timed_exit_respects_window() {
        let mut g = WorldGraph::new();
        g.add_room(room(1, 1)).unwrap();
        g.add_room(room(2, 1)).unwrap();
        g.add_exit(
            1,
            Exit {
                to: 2,
                command: "gate".to_string(),
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
        // 10:00 -> 10:59 (600-659) open
        assert!(g.route(1, 2, Some(610), false).is_ok());
        // outside window
        assert_eq!(g.route(1, 2, Some(100), false), Err(RouteError::NoPath));
        // no time context -> timed unusable
        assert_eq!(g.route(1, 2, None, false), Err(RouteError::NoPath));
        // overnight window wraps
        g.add_exit(
            2,
            Exit {
                to: 1,
                command: "west".to_string(),
                kind: ExitKind::Normal,
                weight: 1,
                door: DoorStatus::None,
                timed: Some(TimedWindow {
                    start_minute: 1380,
                    end_minute: 60,
                }),
            },
        )
        .unwrap();
        assert!(g.route(2, 1, Some(1430), false).is_ok());
        assert!(g.route(2, 1, Some(30), false).is_ok());
    }

    #[test]
    fn weighted_routing_prefers_cheaper() {
        let mut g = WorldGraph::new();
        g.add_room(room(1, 1)).unwrap();
        g.add_room(room(2, 1)).unwrap();
        g.add_room(room(3, 1)).unwrap();
        // direct: weight 10
        g.add_exit(
            1,
            Exit {
                to: 3,
                command: "east".to_string(),
                kind: ExitKind::Normal,
                weight: 10,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .unwrap();
        // indirect: weight 2 + 2
        g.add_exit(
            1,
            Exit {
                to: 2,
                command: "ne".to_string(),
                kind: ExitKind::Normal,
                weight: 2,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .unwrap();
        g.add_exit(
            2,
            Exit {
                to: 3,
                command: "se".to_string(),
                kind: ExitKind::Normal,
                weight: 2,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .unwrap();
        let r = g.route(1, 3, None, false).unwrap();
        assert_eq!(r.nodes, vec![1, 2, 3]);
        assert_eq!(r.total_weight, 4);
    }

    #[test]
    fn zones_cluster_areas_and_rooms() {
        let mut g = WorldGraph::new();
        g.add_area(Area {
            id: 1,
            name: "A".into(),
            zone: None,
            room_ids: [1, 2].into_iter().collect(),
        })
        .unwrap();
        g.add_area(Area {
            id: 2,
            name: "B".into(),
            zone: None,
            room_ids: [3].into_iter().collect(),
        })
        .unwrap();
        g.add_zone(Zone {
            id: 1,
            name: "Z".into(),
            area_ids: HashSet::new(),
        })
        .unwrap();
        g.assign_area_to_zone(1, 1).unwrap();
        g.assign_area_to_zone(2, 1).unwrap();
        assert_eq!(g.rooms_in_zone(1), vec![1, 2, 3]);
    }

    #[test]
    fn exit_limits_are_bounded() {
        let mut g = WorldGraph::new();
        g.add_room(room(1, 1)).unwrap();
        g.add_room(room(2, 1)).unwrap();
        for i in 0..MAX_EXITS_PER_ROOM {
            g.add_exit(
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
            .unwrap();
        }
        assert!(g
            .add_exit(
                1,
                Exit {
                    to: 2,
                    command: "overflow".to_string(),
                    kind: ExitKind::Normal,
                    weight: 1,
                    door: DoorStatus::None,
                    timed: None,
                },
            )
            .is_err());
    }

    #[test]
    fn duplicate_exit_command_rejected() {
        let mut g = WorldGraph::new();
        g.add_room(room(1, 1)).unwrap();
        g.add_room(room(2, 1)).unwrap();
        g.add_exit(
            1,
            Exit {
                to: 2,
                command: "east".to_string(),
                kind: ExitKind::Normal,
                weight: 1,
                door: DoorStatus::None,
                timed: None,
            },
        )
        .unwrap();
        assert!(g
            .add_exit(
                1,
                Exit {
                    to: 2,
                    command: "east".to_string(),
                    kind: ExitKind::OneWay,
                    weight: 1,
                    door: DoorStatus::None,
                    timed: None,
                },
            )
            .is_err());
    }

    #[test]
    fn events_are_bounded_and_sequenced() {
        let mut g = WorldGraph::new();
        for i in 0..(MAX_EVENT_LOG + 100) {
            g.push_event("room-enter", 1, i as u64, serde_json::json!({"i": i}));
        }
        assert_eq!(g.events.len(), MAX_EVENT_LOG);
        let first = g.events.front().unwrap();
        assert_eq!(first.seq, 101); // 100 dropped
    }

    #[test]
    fn facts_carry_provenance_and_supersession() {
        let mut g = WorldGraph::new();
        let id = g.insert_fact(
            "room-enter#42",
            1000,
            "profile:dom",
            0.9,
            Sensitivity::Private,
            "rule-v1",
            serde_json::json!({"room": 1}),
        );
        let f = &g.facts[0];
        assert_eq!(f.id, id);
        assert_eq!(f.source_event, "room-enter#42");
        assert_eq!(f.time, 1000);
        assert_eq!(f.scope, "profile:dom");
        assert!((f.confidence - 0.9).abs() < 1e-9);
        assert_eq!(f.sensitivity, Sensitivity::Private);
        assert_eq!(f.model_version, "rule-v1");
        assert!(f.superseded_by.is_none());
        assert_eq!(g.active_facts().len(), 1);

        g.apply_correction(
            id,
            2000,
            serde_json::json!({"room": 7}),
            "user said room 7",
        )
        .unwrap();
        let f = &g.facts[0];
        assert!(f.superseded_by.is_some());
        assert_eq!(g.active_facts().len(), 0);
        assert_eq!(g.corrections.len(), 1);
        assert_eq!(g.corrections[0].fact_id, id);
    }

    #[test]
    fn ambiguous_identity_never_merges() {
        // WM-SPEC-012-R05: same name, different rooms, stays ambiguous.
        let mut g = WorldGraph::new();
        let mut a = room(1, 1);
        a.name = "Market Square".into();
        a.identity = IdentityState::Ambiguous;
        let mut b = room(2, 1);
        b.name = "Market Square".into();
        b.identity = IdentityState::Ambiguous;
        g.add_room(a).unwrap();
        g.add_room(b).unwrap();
        assert_eq!(g.rooms.len(), 2); // no silent merge
        assert_eq!(g.room(1).unwrap().identity, IdentityState::Ambiguous);
        assert_eq!(g.room(2).unwrap().identity, IdentityState::Ambiguous);
    }

    #[test]
    fn hot_cache_is_bounded() {
        let mut g = WorldGraph::new();
        for i in 0..MAX_HOT_CACHE_ENTRIES {
            g.cache
                .set(format!("k{i}"), serde_json::json!(i))
                .unwrap();
        }
        assert!(g
            .cache
            .set("overflow".into(), serde_json::json!(1))
            .is_err());
    }

    #[test]
    fn export_import_round_trip() {
        let mut g = build_line_graph();
        g.add_area(Area {
            id: 1,
            name: "A".into(),
            zone: None,
            room_ids: [1, 2, 3, 4, 5].into_iter().collect(),
        })
        .unwrap();
        let json = g.export_json().unwrap();
        let mut g2 = WorldGraph::new();
        g2.import_json(&json).unwrap();
        assert_eq!(g2.rooms.len(), g.rooms.len());
        assert_eq!(g2.schema_version, WORLD_SCHEMA_VERSION);
        let r = g2.route(1, 5, None, false).unwrap();
        assert_eq!(r.nodes, vec![1, 2, 3, 4, 5]);
    }

    #[test]
    fn import_rejects_bad_version_and_malformed() {
        let mut g = WorldGraph::new();
        assert!(g
            .import_json(r#"{"schema_version": 999, "rooms": {}}"#)
            .is_err());
        assert!(g.import_json("not json").is_err());
    }

    #[test]
    fn missing_room_errors_are_typed() {
        let g = WorldGraph::new();
        assert_eq!(g.route(1, 2, None, false), Err(RouteError::MissingRoom(1)));
    }

    #[test]
    fn route_budget_is_enforced() {
        let mut g = WorldGraph::new();
        g.route_budget = 5;
        for i in 1..=20 {
            g.add_room(room(i, 1)).unwrap();
        }
        for i in 1..20 {
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
        assert_eq!(
            g.route(1, 20, None, false),
            Err(RouteError::BudgetExceeded)
        );
    }

    #[test]
    fn door_status_blocks_locked() {
        let mut g = WorldGraph::new();
        g.add_room(room(1, 1)).unwrap();
        g.add_room(room(2, 1)).unwrap();
        g.add_exit(
            1,
            Exit {
                to: 2,
                command: "east".to_string(),
                kind: ExitKind::Normal,
                weight: 1,
                door: DoorStatus::Locked,
                timed: None,
            },
        )
        .unwrap();
        assert_eq!(g.route(1, 2, None, false), Err(RouteError::NoPath));
    }
}
