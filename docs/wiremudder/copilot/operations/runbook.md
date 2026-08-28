# WireMudder Player Copilot — Operations (EP-017 M4)

## Health

- The copilot is an optional subsystem. Manual text gameplay never depends
  on it: the pane is a passive observer (`isPassive() == true`) with no
  terminal or command reference.
- Health = the EP-016 route health for the selected route. Local route
  health is checked by the provider adapter (wire-provider-adapters
  `HealthStatus`). If no route is certified/configured, the copilot state
  is `Unavailable` and suggestions are `NoSuggestion{degraded:false}`.

## Readiness

- The copilot is ready when a routing decision selects a route AND a
  provider completion returns. Until then the pane shows Loading, then one
  of: Ready | Disabled | Denied | Degraded | Canceled | Unavailable | Error.
- Deterministic fallback (SPEC-014 fallback): when the provider path is not
  certified, provide deterministic context and rule-based hints only,
  clearly labeled. This is `NoSuggestion{degraded:true}` with a visible
  reason.

## Disable

- Disable by policy: set the routing privacy mode to Disabled or deny the
  route. The engine returns `NoSuggestion` for denied decisions. No code
  change required; the pane transitions to Disabled and clears any stale
  suggestion.

## Recovery

1. Provider unavailable: retry is bounded (SPEC-025-R03). Each suggestion
   attempt is independent; repeated failures keep the pane in
   Unavailable/Degraded and preserve gameplay.
2. Cancellation: `requestCancel()` transitions the pane to Canceled and
   clears the suggestion. A new request starts a fresh attempt.
3. Crash: no persistent state is written by the copilot crate; bounded
   per-profile history is recreated from the pane. Nothing to corrupt.

## Backup / Restore

- No durable copilot state exists yet (EP-017 owns the engine + pane;
  persistence of history to EP-014 storage is a later-node concern).
- Restore = rebuild + rerun tests:
  ```
  cargo test --manifest-path wirecore/crates/wire-copilot/Cargo.toml
  sh tests/wiremudder/ep017/unit/*.sh
  ```

## Upgrade

- Rebuild the client:
  ```
  cmake . && ninja libmudlet_core.a && ninja mudlet
  ```
  The copilot pane compiles from `src/wiremudder/ui/copilot/`; the crate
  compiles from `wirecore/crates/wire-copilot/`.

## Rollback

- Revert the EP-017 additions:
  1. Remove `wiremudder/ui/copilot/copilot_boundary.cpp` and
     `wiremudder/ui/copilot/copilot_boundary.h` from `src/CMakeLists.txt`
     (`mudlet_SRCS` / `mudlet_HDRS`).
  2. Delete `src/wiremudder/ui/copilot/`.
  3. Remove `wirecore/crates/wire-copilot/` (and its Cargo entry if any).
  4. Remove `schemas/wiremudder/copilot/`, `tests/wiremudder/ep017/`,
     `docs/wiremudder/copilot/`.
  5. Remove the discovered-path amendment row for `src/CMakeLists.txt`
     from `.agent/expected-files/EP-017.discovered.txt`.
- The client build returns to the pre-EP-017 state. The ledger remains
  append-only; a rollback is recorded, never edited.

## Metrics

- Engine path latency (perf fixture): p50/p95/max ns per suggestion.
- Disclosure fields give per-request token and cost visibility.
- Failure matrix counts per SPEC-025 class are visible in the pane state.
