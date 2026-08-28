# EP-029 Operations: Bounded Bug Automation and Remediation

## Health

- Crate tests: `CARGO_TARGET_DIR=$PWD/wirecore/target cargo test --manifest-path wirecore/crates/wire-bug-automation/Cargo.toml`
- CLI smoke: `BUG_LAB_STATE=/tmp/w.json CARGO_TARGET_DIR=$PWD/wirecore/target cargo run --quiet --manifest-path tools/wiremudder-bug-lab/Cargo.toml -- status`
- A healthy subsystem reports a valid workflow stage and a non-empty audit
  trail after any transition.

## Readiness

Ready when: the crate compiles with zero warnings, all 19 unit tests pass,
the CLI accepts `intake` and persists state, and the performance fixture
reports `perf fixture EP-029: ok` within the 5 ms budget.

## Disable

The subsystem is optional and fully isolated (no inherited source path).
Disable by not invoking `wiremudder-bug-lab`; no background process, daemon,
or event consumer exists. To remove entirely: delete
`wirecore/crates/wire-bug-automation/`, `tools/wiremudder-bug-lab/`,
`schemas/wiremudder/bugs/`, and `maintenance/wiremudder/`, then revert the
EP-029 node commits. Manual text gameplay is unaffected either way.

## Recovery

- A corrupted or unreadable state file is rejected on load and the CLI
  requires a fresh `intake`; the workflow never proceeds from a partial
  state (fail-closed).
- A cancelled run resumes from the persisted state file; the next command
  continues from the recorded stage.
- Retry budgets are bounded (default 3, ceiling 10); exhaustion emits a
  typed error and the subsystem quarantines rather than looping.

## Backup and Restore

- The only runtime artifact is the state file (`BUG_LAB_STATE`, default
  `bug-lab-state.json`). Backup it to preserve an in-flight remediation.
- Restore by placing the file back and re-running `status`.

## Upgrade

- Rebuild with `cargo build --manifest-path tools/wiremudder-bug-lab/Cargo.toml`.
- Schema version is pinned (`BUG_SCHEMA_VERSION = 1`); a future schema bump
  is a material change requiring the spec-update process.

## Rollback

- The workflow itself never edits production code; canary rollback restores
  the last known good profile (audit entry `rollback`).
- Node rollback: revert the EP-029 M1..M5 commits; no inherited path is
  affected, so the client returns to its pre-EP-029 state exactly.
