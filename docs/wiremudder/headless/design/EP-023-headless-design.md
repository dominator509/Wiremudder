# EP-023 M3 Design: Multi-Session, Headless CLI, and Supervisor

## Boundaries

- `wirecore/crates/wire-headless/` — the deterministic core: session
  scheduler (fairness), headless config, JSONL events, scenario
  validation, request context, supervisor snapshots, cross-session audit,
  and global emergency stop.
- `schemas/wiremudder/headless/` — canonical schemas:
  supervisor-snapshot-v1, jsonl-event-v1, scenario-v1, request-context-v1.
- `tools/wiremudder-supervisor/` — the real headless CLI tool that
  consumes the crate and runs the user-visible multisession flow.
- `src/wiremudder/headless/` — reserved for the desktop headless adapter
  (not required by this node's integration; the CLI tool is the surface).

## Flows

### Session fairness (WM-SPEC-017-R02)

1. `SessionScheduler::create_session` adds a session with a bounded queue
   (256) and inserts it into the round-robin order.
2. `enqueue` rejects when the global emergency stop is active, the session
   is not Ready, the queue is full, or the command id is a duplicate.
3. `serve_round` pops at most ONE command per session per round in
   round-robin order. A busy world with a full queue cannot starve an idle
   world: the scheduler advances past full sessions each round.

### Headless JSONL (WM-SPEC-017-R04)

`JsonlEvent` carries the full SPEC-026-R01 field set: schema version,
time, severity, subsystem, priority, app version, platform, session,
correlation, event, error, latency, queue, drop/coalesce, feature,
privacy, redaction. `HeadlessConfig` defaults to disabling UI, renderer,
audio, and voice for lower overhead.

### Supervisor (WM-SPEC-017-R06)

`Supervisor::snapshot(session)` reports state, room, last command,
AI/autopilot state, risk queue length, route label, token spend, health,
and queue length. The supervisor is a passive observer (`is_passive()`);
the scheduler owns the global emergency stop.

### Cross-session rules and emergency stop

`SessionScheduler::audit_trail()` records session-create, session-enqueue,
and the global emergency stop. `emergency_stop()` denies all new enqueues
and marks every session Canceled — the same contract desktop and headless
share (WM-SPEC-024-R08).

## Verification

- M2 unit: `sh tests/wiremudder/ep023/unit/wire-headless.sh`
- M3 integration: `sh tests/wiremudder/ep023/integration/*.sh`
- M3 e2e: `sh tests/wiremudder/ep023/e2e/001-headless-multisession.sh`
  runs the real Rust e2e flow and the real supervisor CLI tool.
- Node verifier: `sh scripts/node-verifiers/EP-023.sh M3`

## Rollback

- Delete `tools/wiremudder-supervisor/`, `wirecore/crates/wire-headless/`,
  and `schemas/wiremudder/headless/`.
- The repository returns to the pre-EP-023 state; no inherited path is
  modified by this node.
