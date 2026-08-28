# WireMudder Soul, Agent Council, Skills, and Memory Permissions — Operations (EP-018 M4)

## Health

- The soul/agents subsystem is optional. Manual text gameplay never depends
  on it: the Soul pane is a passive observer (`canGrantAuthority() == false`)
  with no command-send, skill-install, or council-convene path.
- Health = the crate unit suites are green and the panes are compiled into
  the client:
  ```
  cargo test --manifest-path wirecore/crates/wire-soul/Cargo.toml
  cargo test --manifest-path wirecore/crates/wire-agents/Cargo.toml
  sh tests/wiremudder/ep018/unit/*.sh
  ```

## Readiness

- The subsystem is ready when the Soul pane is Ready (a valid Soul document
  is loaded and the Studio shows compiled-prompt preview and policy
  precedence) and the agent registry surfaces skills, permissions, and
  council records.
- Deterministic states (SPEC-025): Loading, Ready, Disabled, Denied,
  Degraded, Canceled, Unavailable, Error. A denied or unavailable state
  clears the pane and preserves manual gameplay.

## Disable

- Disable by policy: deny council permission (council `require_permission`
  stays true), keep memory permissions at default deny-all, and do not
  install/enable any skill. No code change required; the pane transitions to
  Disabled and the engine returns denied/disabled results.

## Recovery

1. Malformed/oversized soul: validation returns a typed `SoulError` with a
   safe user message; the Studio audit records the denial and the pane shows
   the error state. Retry with a corrected document.
2. Timeout/cancellation: the decision path is deterministic and bounded; a
   canceled pane request clears stale data. A new request starts fresh.
3. Resource exhaustion: the Studio audit is bounded at 200 entries, the
   council log at 100 records, the skill tree at 500 skills. Exhaustion
   returns a typed `Exhaustion` error, never a silent drop.
4. Crash: no durable state is written by either crate; all state is
   in-memory and recreated on restart. Nothing to corrupt.

## Backup / Restore

- No durable runtime state exists (souls, skills, and permissions are
  profile-level documents handled by later nodes). Backup = the schemas and
  crate sources under version control.
- Restore = rebuild + rerun the gates:
  ```
  cargo test --manifest-path wirecore/crates/wire-soul/Cargo.toml
  cargo test --manifest-path wirecore/crates/wire-agents/Cargo.toml
  sh tests/wiremudder/ep018/unit/*.sh
  ```

## Upgrade

- Rebuild the client:
  ```
  cmake . && ninja libmudlet_core.a && ninja mudlet
  ```
  The Soul pane compiles from `src/wiremudder/ui/soul/`; the crates compile
  from `wirecore/crates/wire-soul/` and `wirecore/crates/wire-agents/`.

## Rollback

- Revert the EP-018 additions:
  1. Remove `wiremudder/ui/soul/soul_boundary.cpp` and
     `wiremudder/ui/soul/soul_boundary.h` from `src/CMakeLists.txt`
     (`mudlet_SRCS` / `mudlet_HDRS`).
  2. Delete `src/wiremudder/ui/soul/`.
  3. Remove `wirecore/crates/wire-soul/` and `wirecore/crates/wire-agents/`
     (and their Cargo workspace entries if any).
  4. Remove `schemas/wiremudder/agents/`, `tests/wiremudder/ep018/`,
     `docs/wiremudder/agents/`.
  5. Remove the discovered-path amendment row for `src/CMakeLists.txt`
     from `.agent/expected-files/EP-018.discovered.txt`.
- The client build returns to the pre-EP-018 state. The ledger remains
  append-only; a rollback is recorded, never edited.

## Metrics

- Decision-path latency (perf fixture `perf_agents`): p50/p95/max ns for
  soul validation + permission checks + skill lookup + council convene.
  Budget: 1 ms p95 (SPEC-004-R11); provider round-trips are measured in
  M5 live-fire, not here.
- Denial counts: Studio audit records every rejected soul; the security
  matrix asserts denials are audited and safe user messages leak no
  internals.
- Failure matrix counts per SPEC-025 class are covered by
  `tests/wiremudder/ep018/failure/001-matrix.sh` and the security matrix by
  `tests/wiremudder/ep018/security/001-matrix.sh`.
