# WireMudder Assistance: Operations Runbook (EP-020 M4)

## Health

The assistance stack is optional. Health is observable through the pane
state: `loading`, `ready`, `disabled`, `denied`, `degraded`, `canceled`,
`unavailable`, `error`. A healthy stack reaches `ready` and keeps quest,
tactical, and narrator surfaces populated.

## Readiness

- Quest Compass: ready when the quest log is reachable (bounded, max 500
  quests) and at least one cited quest is displayed.
- Tactical HUD: ready when the latest bounded snapshot (max 64 nearby
  entities, max 20 history entries) is displayed.
- Personal Narrator: ready when summaries disclose source and redaction
  flag; the narrator is always read-only.

## Disable

- Set the pane to `disabled`. Non-ready states clear the pane so stale
  data never reaches the player.
- Optional failure preserves manual text gameplay: the terminal, input,
  connection, and emergency stop are never touched by assistance code.

## Recovery

- Quest log: typed errors are `Validation`, `NotFound`, `Exhaustion`.
  After a rejected malformed update, valid tracking resumes.
- Tactical HUD: typed errors are `Validation`, `Oversized`, `StaleSnapshot`.
  After rejection, the next valid snapshot is accepted.
- Narrator: typed errors are `Validation`, `LoadShedding`. Load shedding
  drops non-critical narration; narration resumes when load normalizes.

## Backup and Restore

- Quest log and tactical state are ephemeral current-state data rebuilt
  from the live world stream. No persistent backup is required.
- Narrator recent summaries are a bounded in-memory buffer (max 50) and
  are rebuilt from current state.

## Upgrade

- Schema versions are stable (`QUEST_SCHEMA_VERSION`, `TACTICAL_SCHEMA_VERSION`,
  `NARRATOR_SCHEMA_VERSION` all = 1). No migration is required for this node.

## Rollback

1. Remove `wiremudder/ui/assistance/assistance_boundary.cpp` and
   `wiremudder/ui/assistance/assistance_boundary.h` from `src/CMakeLists.txt`.
2. Delete `src/wiremudder/ui/assistance/`.
3. Delete `wirecore/crates/wire-quest/`, `wirecore/crates/wire-tactical/`,
   `wirecore/crates/wire-narrator/`.
4. Delete `schemas/wiremudder/assistance/`.
5. The client build returns to its pre-EP-020 state; manual gameplay is
   unaffected at every step.

## Verified Commands

- `sh scripts/node-verifiers/EP-020.sh M4` -> `EP-020 M4: ok`
- `cargo run --release --example perf_assistance` -> `perf fixture: ok`
- `sh tests/wiremudder/ep020/failure/001-matrix.sh` -> `failure EP-020 M4 matrix: ok`
- `sh tests/wiremudder/ep020/security/001-matrix.sh` -> `security EP-020 M4 matrix: ok`
