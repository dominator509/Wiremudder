# WireMudder World Brain, World Bible, Time Machine: Operations (EP-021 M4)

## Health

The world-memory stack is optional. Health is observable through typed
errors (SPEC-025): `Validation`, `NotFound`, `Exhaustion`, and (Time
Machine) `NotApproved`. A healthy stack accepts observations, stores
continuity metadata, and snapshots/restores user-approved checkpoints.

## Readiness

- World Brain: ready when facts carry full provenance and corrections
  supersede without erasing history.
- World Bible: ready when region continuity metadata is stored and the
  deterministic export succeeds.
- Time Machine: ready when snapshots are compacted, exportable, and
  restorable only after user approval.

## Disable

- Each crate is an independent bounded store; drop the instance to
  disable. Optional failure preserves manual text gameplay: nothing in
  the memory stack can send a command (`can_send_command() == false`).

## Recovery

- World Brain: after a rejected malformed observation or a failed
  correction (not-found), the next valid observation succeeds.
- World Bible: after an oversized/binary token rejection, the next valid
  upsert succeeds.
- Time Machine: after a rejected restore (not approved), approval then
  restore succeeds.

## Backup and Restore

- World Bible export is a deterministic JSON document (metadata only,
  no protected assets, no secrets) that serves as a portable backup.
- Time Machine snapshots are compacted views; restoring a user-approved
  checkpoint replaces the hot view without destroying durable history.

## Upgrade

- Schema versions are stable (`WORLD_BRAIN_SCHEMA_VERSION`,
  `WORLD_BIBLE_SCHEMA_VERSION`, `TIME_MACHINE_SCHEMA_VERSION` all = 1).
  No migration is required for this node.

## Rollback

1. Delete `wirecore/crates/wire-world-brain/`,
   `wirecore/crates/wire-world-bible/`, `wirecore/crates/wire-time-machine/`.
2. Delete `schemas/wiremudder/memory/`.
3. Durable world state returns to pre-EP-021 behavior; manual gameplay
   is unaffected at every step.

## Verified Commands

- `sh scripts/node-verifiers/EP-021.sh M4` -> `EP-021 M4: ok`
- `cargo run --release --example perf_world_memory` -> `perf fixture: ok`
- `sh tests/wiremudder/ep021/failure/001-matrix.sh` -> `failure EP-021 M4 matrix: ok`
- `sh tests/wiremudder/ep021/security/001-matrix.sh` -> `security EP-021 M4 matrix: ok`
