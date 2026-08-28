# EP-022 M4 Operations: Macro Forge, Trigger Test Lab, and AI Debugger

## Health

- `wire-debugger` crate surfaces are in-memory deterministic state
  (MacroForge drafts, TriggerLab fixtures/runs, AiDebugger diagnoses,
  PerformanceStats samples, ScriptDebugger variables/timeline).
- Pane state follows SPEC-025: Loading, Ready, Disabled, Denied, Degraded,
  Canceled, Unavailable, Error. Non-ready states clear the pane.

## Readiness

- Ready when the pane is populated by the client's debugger controller and
  the crate surfaces are constructible (no external dependencies).
- If a provider or worker is unavailable, the AI Debugger returns
  `DeniedPolicy`/typed `DebugDenial`; the pane shows `Denied`/`Unavailable`.

## Disable

- The pane has no command path and no gate-editing surface; disabling it
  removes only the observer UI. Manual text gameplay is unaffected.
- Macro Forge drafts are preview-only until approved; disabling approval
  leaves every draft non-runnable.

## Recovery

- A failed replay (timeout/budget exhaustion) records no partial run and
  leaves the fixture available for retry (compensation: failed run not
  appended to run history).
- Restarting the client rebuilds in-memory debugger state from the last
  persisted world data; drafts and fixtures that were approved are
  re-created only through their normal approval flows.

## Backup / Restore

- Debugger state is ephemeral by design (SPEC-019 local-first, bounded
  ring buffers). No secrets or private variable values are persisted.
- Restore of a fixture requires re-adding it via the Trigger Test Lab
  interface; malformed fixtures are rejected before any replay side effect.

## Upgrade / Rollback

- Upgrade: rebuild `wirecore/crates/wire-debugger/` with the new crate and
  re-add any fixtures; schemas under `schemas/wiremudder/debug/` are
  versioned (v1) and validated as JSON.
- Rollback: remove the power-tools entries from `src/CMakeLists.txt`
  (`mudlet_SRCS` and headers), delete `src/wiremudder/ui/power-tools/`,
  and revert `wirecore/crates/wire-debugger/` + `schemas/wiremudder/debug/`.
  The client returns to the pre-EP-022 state.

## Monitoring

- `PerformanceStats` records every measured sample with `over_budget`;
  `slow_offenders()` returns sorted offenders (p95, worst) for
  WM-SPEC-008-R02 diagnostics.
- Replay runs are bounded (ring of 256) and never include private values.

## Bounded Recovery Runbook

1. Health: run `sh scripts/node-verifiers/EP-022.sh M4` — all M4 checks
   must pass (failure, security, performance).
2. If a check fails, read the typed denial in the evidence log; the crate
   returns `DebugDenial` variants (NotApproved, UnavailableDependency,
   Timeout, Cancelled, MalformedInput, DuplicateRequest, DeniedPolicy,
   BudgetExhausted, OversizedInput), never silent success.
3. Apply the smallest fix inside the EP-022 fences, re-run the failing
   check, then re-run the full M4 verifier.
4. Do not weaken a gate: budgets, bounds, denials, and redaction are
   binding.
