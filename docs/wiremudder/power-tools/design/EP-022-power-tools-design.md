# EP-022 M3 Design: Macro Forge, Trigger Test Lab, and AI Debugger

## Boundaries

- `wirecore/crates/wire-debugger/` — the deterministic core: Macro Forge,
  Trigger Test Lab, script debugger (variable inspection + event timeline),
  AI Debugger, performance statistics, and safe patch proposals.
- `schemas/wiremudder/debug/` — canonical schemas: automation-draft-v1,
  replay-fixture-v1, ai-diagnosis-v1, budget-sample-v1.
- `src/wiremudder/ui/power-tools/` — passive Qt pane surface (no command
  path, no gate editing).
- `compatibility/automation/` — deterministic replay fixtures consumed by
  the Trigger Test Lab (M4).

## Flows

### Macro Forge

1. `MacroForge::create(id, kind, name, body, at_ms)` stores a draft with
   `preview_only=true` and `approved=false`.
2. The pane shows drafts as preview-only. `requestApproveDraft(id)` records
   user intent only.
3. `MacroForge::approve(id)` flips `approved=true`, `preview_only=false`.
   A draft is runnable only when `approved && !preview_only`.

### Trigger Test Lab

1. `TriggerLab::add_fixture(ReplayFixture)` validates strict ascending
   `at_step`, non-empty id/name, and the step bound.
2. `TriggerLab::replay(id, handler, budget_ms)` feeds each fixture event to
   the real script handler, records effects, enforces the budget
   (`BudgetExhausted`), and stores the bounded run history.

### AI Debugger

1. Evidence must be user-approved first: `approve_evidence(id, lines)`.
2. `diagnose(...)` fails with `DeniedPolicy` unless the evidence id was
   approved; the diagnosis embeds the approved evidence lines as citations.
3. `self_certified` is pinned `false` (WM-SPEC-019-R06). The pane pins
   `gateEditable=false` and `canEditGates()=false`.
4. Suggested patches (`PatchProposal`) start `validated=false`; only normal
   Graphlock validation can mark them validated (EP-022 obligation 6).

### Performance statistics

`PerformanceStats::record(run_id, kind, name, elapsed_ms, budget_ms)` flags
`over_budget`; `slow_offenders()` returns offenders sorted by worst elapsed
with p95 and sample count (WM-SPEC-008-R02).

## Verification

- M2 unit: `sh tests/wiremudder/ep022/unit/wire-debugger.sh`
- M3 integration: `sh tests/wiremudder/ep022/integration/*.sh`
- M3 e2e: `sh tests/wiremudder/ep022/e2e/001-power-tools-pane.sh` compiles
  the pane harness against real Qt6 and runs the Rust e2e flow.
- Node verifier: `sh scripts/node-verifiers/EP-022.sh M3`

## Rollback

- Remove `wiremudder/ui/power-tools/power_tools_boundary.{h,cpp}` entries
  from `src/CMakeLists.txt` (mudlet_SRCS and headers).
- Delete `src/wiremudder/ui/power-tools/`.
- Delete `wirecore/crates/wire-debugger/` and revert `schemas/wiremudder/debug/`.
- The client build returns to pre-EP-022 state.
