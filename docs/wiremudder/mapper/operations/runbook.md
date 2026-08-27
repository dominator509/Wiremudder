# WireMudder Mapper / World Graph Operations Runbook (EP-013 M4)

## Health and Readiness

- World-graph crate health: `cargo test --manifest-path wirecore/crates/wire-world-graph/Cargo.toml`
  (17+ unit tests). A green result means the core invariants hold.
- Mapper boundary health: `sh tests/wiremudder/ep013/unit/002-mapper-boundary.sh`
  (compiles and runs the C++ boundary).
- Parity health: `sh tests/wiremudder/ep013/integration/001-world-graph-parity.sh`
  (Rust vs C++ decisions identical).

## Disable

- The mapper/world-graph is an optional system. Manual gameplay is
  independent: text input and output never pass through the world graph.
- To disable routing assistance: stop calling the boundary; the hot
  cache and event log are inert until used.

## Recovery

- A malformed snapshot is rejected at import; the previous in-memory
  graph is untouched (import builds a fresh graph then swaps).
- A route budget exhaustion returns `BudgetExceeded`; no partial route
  is returned and no state is mutated.

## Backup and Restore

- Backup: export a versioned snapshot
  (`WorldGraph::export_json` / Rust example `snapshot_export`).
- Restore: import the snapshot (`import_json`); unknown schema versions
  are refused, so restores are schema-pinned.

## Upgrade

- Bump `WORLD_SCHEMA_VERSION` only with a migration path. Import
  refuses unknown versions; old snapshots must be migrated before
  import or the boundary stays on the previous schema.

## Rollback

- Revert the node commit (M1..M5 are separate commits; never cross a
  completed green tag). No inherited paths are edited by this node, so
  rollback is a pure revert of namespaced code.

## Bounded Resources

- Rooms: 1,000,000 max. Exits per room: 64 max. Events: 8192 log cap.
- Hot cache: 4096 entries. Route exploration: per-graph budget
  (default 1,000,000 nodes), typed `BudgetExceeded`.
