# WireMudder Guarded Autopilot — Operations (EP-019 M4)

## Health

- The autopilot is an optional subsystem. Manual text gameplay never
  depends on it: the pane is a passive observer (`canSendCommand() ==
  false`) with no command path.
- Health = the crate unit suite is green and the panes are compiled into
  the client:
  ```
  cargo test --manifest-path wirecore/crates/wire-autopilot/Cargo.toml
  sh tests/wiremudder/ep019/unit/*.sh
  ```

## Readiness

- The autopilot is ready when it is enabled for the active profile and
  status() is Ready. Until enabled the status is Disabled (off by default).
- Deterministic states: Disabled, Ready, Paused(StaleReason), Denied,
  Error. A paused or denied state refuses new proposals and preserves
  manual gameplay.

## Disable

- Disable by policy: set the profile mode to Disabled (the default) or
  call disable(). Pending actions are cancelled and audited. No code
  change required.

## Recovery

1. Stale state: `set_stale(reason)` pauses; re-validate world state,
   command policy, route, and approvals, then `clear_stale()` resumes.
2. Rate limit: the per-window cap is deterministic; the window rolls over
   automatically. No action required; wait for the window.
3. Queue full: cancel or confirm pending actions; the queue is bounded at
   `queue_capacity`.
4. Emergency stop: `emergency_stop()` cancels the queue and blocks new
   proposals; `release_emergency_stop()` resumes.
5. Crash: no durable state is written by the crate; all state is in-memory
   and recreated on restart. Nothing to corrupt.

## Backup / Restore

- No durable runtime state exists (autopilot config is a profile-level
  document handled by later nodes). Backup = the crate sources and schemas
  under version control.
- Restore = rebuild + rerun the gates:
  ```
  cargo test --manifest-path wirecore/crates/wire-autopilot/Cargo.toml
  sh tests/wiremudder/ep019/unit/*.sh
  ```

## Upgrade

- Rebuild the client:
  ```
  cmake . && ninja libmudlet_core.a && ninja mudlet
  ```
  The autopilot pane compiles from `src/wiremudder/ui/autopilot/`; the
  crate compiles from `wirecore/crates/wire-autopilot/`.

## Rollback

- Revert the EP-019 additions:
  1. Remove `wiremudder/ui/autopilot/autopilot_boundary.cpp` and
     `wiremudder/ui/autopilot/autopilot_boundary.h` from
     `src/CMakeLists.txt` (`mudlet_SRCS` / `mudlet_HDRS`).
  2. Delete `src/wiremudder/ui/autopilot/`.
  3. Remove `wirecore/crates/wire-autopilot/`.
  4. Remove `schemas/wiremudder/autopilot/`, `tests/wiremudder/ep019/`,
     `docs/wiremudder/autopilot/`.
  5. Remove the discovered-path amendment row for `src/CMakeLists.txt`
     from `.agent/expected-files/EP-019.discovered.txt`.
- The client build returns to the pre-EP-019 state. The ledger remains
  append-only; a rollback is recorded, never edited.

## Metrics

- Decision-path latency (perf fixture `perf_autopilot`): p50/p95/max ns
  for propose + confirm/send including audit. Budget: 1 ms p95
  (SPEC-004-R11).
- Rate-limit denials, stale pauses, emergency stops, and every send are
  recorded in the autopilot audit (complete audit, WM-SPEC-009-R09).
- Failure matrix counts per SPEC-025 class are covered by
  `tests/wiremudder/ep019/failure/001-matrix.sh` and the security matrix
  by `tests/wiremudder/ep019/security/001-matrix.sh`.
