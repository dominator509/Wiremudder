# EP-029 Design: Bounded Bug Automation and Remediation

## Purpose

Provide evidence-backed bug intake, deduplication, reproduction, diagnosis,
patch planning, independent review, canary recommendation, rollback, and
terminal BLOCKED behavior for future autonomous remediation (SPEC-019-R09).
The subsystem is optional, local-first, and never edits production code
automatically (node fallback: generate a human-reviewed diagnostic and
patch plan only).

## Boundaries

- `wirecore/crates/wire-bug-automation/` — the bounded state machine.
- `tools/wiremudder-bug-lab/` — the operator CLI that drives it.
- `schemas/wiremudder/bugs/` — canonical report, workflow, and BLOCKED
  schemas.
- `maintenance/wiremudder/` — maintenance boundary for campaigns and
  rollback confirmations.

No inherited source path is edited by this node; the subsystem is isolated
so optional failure preserves manual text gameplay.

## State Machine (WM-SPEC-019-R09)

`intake -> reproduction -> diagnosis -> patch -> validation -> review ->
canary -> rollback -> done` with terminal `blocked` reachable from any
non-terminal stage.

- Intake redacts secrets at the boundary (`redact()`).
- Reproduction must be evidence-backed; diagnosis without reproduction is
  refused.
- Patch plans must stay inside the owning subsystem.
- Validation requires an observed test result.
- Review must be independent (reviewer != planner); P0/P1 bugs require a
  performance review; voice/provider/update/package/security bugs require a
  security review (SPEC-019-R10).
- Canary requires a rollback plan; rollback must restore last known good.
- Completion requires an approved review, a passed canary, or a completed
  rollback.
- Every transition is recorded in the append-only audit trail
  (WM-SPEC-025-R05).

## Retries (WM-SPEC-025-R03)

Bounded (default 3, hard ceiling 10), jittered backoff, idempotency keys
required for destructive or ambiguous effects, signatures tracked; repeated
failures quarantine the subsystem (WM-SPEC-025-R04).

## Routing (WM-FEAT-0228)

`PriorityRouter` enqueues by priority ring (P0 first) and subsystem; P0/P1
are never starved by lower-priority work.

## Commands

Build and test the crate:

```
CARGO_TARGET_DIR=$PWD/wirecore/target cargo test --manifest-path wirecore/crates/wire-bug-automation/Cargo.toml
```

Drive the CLI (state file via `BUG_LAB_STATE`, default `bug-lab-state.json`):

```
BUG_LAB_STATE=/tmp/w.json CARGO_TARGET_DIR=$PWD/wirecore/target \
  cargo run --quiet --manifest-path tools/wiremudder-bug-lab/Cargo.toml -- \
  intake lua P2 "lua panic on reconnect token=hunter2-f00. happens after idle."
# ... reproduce, diagnose, plan, validate, review, canary, done | block
```

Observed sentinel from the M3 e2e: `e2e bug-remediation-replay: ok`.

## Rollback

The workflow itself never edits production code; rollback of a canary
restores the last known good profile (audit entry `rollback`). To remove
the subsystem entirely: delete the crate, tool, schemas, and maintenance
directories and revert the node commit; no inherited path is affected.

## Fail-Closed Behavior

- Missing reproduction: refused.
- Cross-subsystem patch: refused.
- Self-review: refused.
- Missing performance/security review for the required classes: refused.
- Missing rollback plan on canary: refused.
- Denied review: complete BLOCKED report with evidence, retry signatures,
  and human next steps.
