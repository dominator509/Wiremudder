# WireMudder Mapper, World Graph, and Routing (EP-013)

## Design: M2 Core Behavior

### 1. Architecture

EP-013 introduces two namespaced implementations of the same world-graph
contract plus versioned schemas:

- `wirecore/crates/wire-world-graph/` - Rust core (SPEC-012).
- `src/wiremudder/mapper/mapper_boundary.{h,cpp}` - C++/Qt boundary with
  identical invariants.
- `schemas/wiremudder/world/*.schema.json` - version 1 JSON schemas.

The inherited Mudlet mapper (TMap, TRoom, TArea, T2DMap, TMapView,
TMapViewManager, TAstar.h) remains canonical and unedited. Evidence:
WM-SRC-000094..000100.

### 2. World Model

- Room: id, area, name, coordinates (x/y/z), identity state.
- Area: id, name, optional zone, room membership (WM-FEAT-0165).
- Zone: id, name, area membership (WM-FEAT-0165).
- Exit: target room, command, kind (normal/hidden/locked/one-way/portal),
  weight, door status, optional timed window (WM-FEAT-0166, R04, R05-R07).
- Door status mirrors inherited `TRoom::setDoor` semantics (0 none,
  1 open, 2 closed, 3 locked).

### 3. Routing (WM-FEAT-0167)

Deterministic Dijkstra (same inputs, same outputs) with:

- Weighted edges (weight >= 1).
- One-way and portal exits traversed only in their declared direction.
- Hidden exits require caller opt-in (`allow_hidden`).
- Locked exits and locked doors block traversal.
- Timed windows (minutes of day, overnight wrap supported) require an
  explicit `now`; without time context timed exits are unusable.
- Bounded node budget (MAX_ROUTE_NODES) and typed errors.

Both implementations (Rust, C++) compute the same routes.

### 4. Derived Facts and Corrections (WM-SPEC-012-R02/R10)

- Every fact records: id, source event, time, profile/world scope,
  confidence [0,1], sensitivity (public/private/secret), model/rule
  version, supersession state.
- A user correction supersedes the target fact (preserving history in
  the corrections list) and marks the fact superseded.
- Corrections never mutate or delete the original fact record.

### 5. Hot Cache (WM-SPEC-012-R03)

- Bounded in-memory key/value cache (4096 entries).
- Current-room pointer is separate and cheap to read.
- Durable writes are asynchronous by design (out of band of the cache).

### 6. Events (WM-SPEC-012-R02/R03)

- Typed events carry a monotonic sequence, kind, room, time, payload.
- Log is bounded (8192 entries, oldest dropped).

### 7. Import/Export (WM-FEAT-0168, SPEC-021)

- Export produces a versioned JSON snapshot.
- Import rejects unknown schema versions and malformed payloads.
- Round-trip is byte-deterministic in structure.

### 8. Deterministic Invariants

1. Shortest path by total weight.
2. One-way not reversible.
3. Locked/hidden/timed exits blocked exactly as declared.
4. Timed overnight windows wrap past midnight.
5. Zone clustering resolves areas -> rooms deterministically.
6. Duplicate exit commands and per-room exit bound rejected.
7. Facts carry full provenance; corrections supersede, never delete.
8. Ambiguous identity never merges two rooms (R05).
9. Hot cache bounded.
10. Import/export round-trip preserves routes.

### 9. Verification

- Rust: `cargo test` (17 unit tests).
- C++: `mapper_harness.cpp` compiled against Qt 6.8.2, 10 invariant
  groups.
- Schemas: JSON validity + required-field contracts.

### 10. Rollback

Revert M2 commit; M1 fences and verifier remain intact. No inherited
paths were edited; no production surface changed.
