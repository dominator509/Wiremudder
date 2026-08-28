# WireMudder Assistance: Design (EP-020 M3)

## Purpose

Quest Compass, Tactical HUD, and Personal Narrator give the player cited
quest state, a bounded tactical snapshot, and spoken/text summaries that
disclose their source, respect privacy, and never send commands by
themselves.

## Architecture

- `wirecore/crates/wire-quest/` — cited quest tracking with observed,
  inferred, completed, failed, and user-corrected state (WM-SPEC-012-R06).
- `wirecore/crates/wire-tactical/` — bounded current tactical snapshots
  (WM-SPEC-012-R07).
- `wirecore/crates/wire-narrator/` — read-only summaries with source
  disclosure, privacy redaction, and load shedding (WM-SPEC-015-R06).
- `src/wiremudder/ui/assistance/assistance_boundary.{h,cpp}` — passive
  Qt surface compiled into the actual Mudlet-derived client build list
  (`src/CMakeLists.txt`, discovered amendment WM-SRC-000136).

## User-Visible Flow

1. Client starts; pane reports `loading`.
2. WireCore bridge publishes quest log, tactical snapshot, and narrator
   summaries; pane reports `ready`.
3. Quest Compass shows cited clues and marks inferred/user-corrected
   quests with visible uncertainty.
4. Tactical HUD shows the bounded current snapshot (room, health, energy,
   threat, nearby).
5. Narrator shows summaries whose text is read-only: no command path
   exists on the boundary (`canSendCommand() == false`).

## States (SPEC-025)

`loading`, `ready`, `disabled`, `denied`, `degraded`, `canceled`,
`unavailable`, `error`. Any non-ready, non-loading state clears the pane
so stale data never reaches the player.

## Privacy

Narrator redaction scrubs full secret-shaped token values after markers
(`sk-`, `sbp_`, `Bearer `, `password=`, `api_key=`, `secret=`) including
repeated occurrences. Redacted summaries are flagged.

## Failure Behavior

Optional assistance failure preserves manual text gameplay. The pane is
passive in every state and the narrator never sends commands.

## Rollback

- Remove `assistance_boundary.{h,cpp}` from `src/CMakeLists.txt`.
- Delete `src/wiremudder/ui/assistance/`.
- Delete `wirecore/crates/wire-quest|wire-tactical|wire-narrator/`.
- The client build returns to its pre-EP-020 state.

## Observed Commands

- `sh scripts/node-verifiers/EP-020.sh M3` -> `EP-020 M3: ok`
- `sh scripts/scope-audit.sh EP-020` -> `scope audit EP-020: ok`
- `sh tests/wiremudder/ep020/e2e/001-assistance-pane.sh` -> `e2e EP-020 M3 assistance-pane: ok`
