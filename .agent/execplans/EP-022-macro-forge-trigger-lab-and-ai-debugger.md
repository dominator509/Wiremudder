NODE-META-BEGIN
ID: EP-022
DEPS: EP-010,EP-017,EP-021
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-022
VERIFY_SENTINEL: node verify EP-022: ok
GREEN_TAG: green/EP-022
NODE-META-END

# 1. Purpose and Big Picture

Implement Macro Forge, Trigger Test Lab, replay-driven script debugging, variable inspection, event timeline, AI-assisted diagnosis, performance statistics, and safe patch proposals.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-022.md`.
- Own features: WM-FEAT-0106, WM-FEAT-0107, WM-FEAT-0108, WM-FEAT-0127, WM-FEAT-0161, WM-FEAT-0162.
- Own requirements: WM-SPEC-008-R02, WM-SPEC-008-R07, WM-SPEC-008-R08, WM-SPEC-019-R06.
- Use namespaced new code and the smallest evidence-backed inherited integration patch.
- Leave the repository buildable, reversible, auditable, and cold-resumable.

# 3. Non-goals

- No greenfield rewrite, mass rename, broad cleanup, or alternate architecture.
- No work owned by a later node.
- No production publish, stable signing, or key access.
- No mock, stub, demo success, sample success, placeholder behavior, or hidden fallback in production.
- No provider, platform, import format, or asset certification without live-fire evidence.
- No weakening of Graphlock, compatibility, security, privacy, performance, accessibility, or test gates.

# 4. Context and Orientation

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-010, EP-017, EP-021. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-022.md`
- `.agent/expected-files/EP-022.txt`
- `.agent/expected-files/EP-022.discovered.txt`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-022.txt`. The milestone fence is `.agent/milestone-files/EP-022-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-022.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-022-macro-forge-trigger-lab-and-ai-debugger.md`
- `.agent/node-contracts/EP-022.md`
- `.agent/expected-files/EP-022.txt`
- `.agent/expected-files/EP-022.discovered.txt`
- `.agent/milestone-files/EP-022-M1.txt`
- `.agent/milestone-files/EP-022-M2.txt`
- `.agent/milestone-files/EP-022-M3.txt`
- `.agent/milestone-files/EP-022-M4.txt`
- `.agent/milestone-files/EP-022-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-022/`
- `scripts/node-verifiers/EP-022.sh`
- `tests/live-fire/LF-022-macro-trigger-debug.sh`
- `tests/wiremudder/ep022/`
- `docs/wiremudder/power-tools/`
- `src/wiremudder/ui/power-tools/`
- `wirecore/crates/wire-debugger/`
- `compatibility/automation/`
- `schemas/wiremudder/debug/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-022.md`.
- Accepted specifications: SPEC-008, SPEC-014, SPEC-019.
- Live-fire: `LF-022` `macro-trigger-debug`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Macro Forge, Trigger Lab, and AI Debugger.

READ:
- `.agent/execplans/EP-022-macro-forge-trigger-lab-and-ai-debugger.md`
- `.agent/node-contracts/EP-022.md`
- `.agent/milestone-files/EP-022-M1.txt`
- `.agent/expected-files/EP-022.txt`
- `.agent/expected-files/EP-022.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-022-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0106, WM-FEAT-0107, WM-FEAT-0108, WM-FEAT-0127, WM-FEAT-0161, WM-FEAT-0162.
3. Review owned requirements: WM-SPEC-008-R02, WM-SPEC-008-R07, WM-SPEC-008-R08, WM-SPEC-019-R06.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-022`
2. `sh scripts/record-evidence.sh EP-022 M1 "EP-022 M1: ok" -- sh scripts/node-verifiers/EP-022.sh M1`
3. `sh scripts/scope-audit.sh EP-022`

EXPECT:
- `EP-022 M1: ok`
- `scope audit EP-022: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-022 MILESTONE_PASS "M1 EP-022 M1: ok; evidence=.agent/state/evidence/EP-022/M1"`

FALLBACK: Offer deterministic replay, match visualization, and manual editors without AI-generated patches.

COMMIT: `git add -A && git commit -m "[EP-022][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Macro Forge, Trigger Lab, and AI Debugger inside namespaced boundaries.

READ:
- `.agent/execplans/EP-022-macro-forge-trigger-lab-and-ai-debugger.md`
- `.agent/node-contracts/EP-022.md`
- `.agent/milestone-files/EP-022-M2.txt`
- `.agent/expected-files/EP-022.txt`
- `.agent/expected-files/EP-022.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-022-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-022`
2. `sh scripts/record-evidence.sh EP-022 M2 "EP-022 M2: ok" -- sh scripts/node-verifiers/EP-022.sh M2`
3. `sh scripts/scope-audit.sh EP-022`

EXPECT:
- `EP-022 M2: ok`
- `scope audit EP-022: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-022 MILESTONE_PASS "M2 EP-022 M2: ok; evidence=.agent/state/evidence/EP-022/M2"`

FALLBACK: Offer deterministic replay, match visualization, and manual editors without AI-generated patches.

COMMIT: `git add -A && git commit -m "[EP-022][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Macro Forge, Trigger Lab, and AI Debugger with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-022-macro-forge-trigger-lab-and-ai-debugger.md`
- `.agent/node-contracts/EP-022.md`
- `.agent/milestone-files/EP-022-M3.txt`
- `.agent/expected-files/EP-022.txt`
- `.agent/expected-files/EP-022.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-022-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-022`
2. `sh scripts/record-evidence.sh EP-022 M3 "EP-022 M3: ok" -- sh scripts/node-verifiers/EP-022.sh M3`
3. `sh scripts/scope-audit.sh EP-022`

EXPECT:
- `EP-022 M3: ok`
- `scope audit EP-022: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-022 MILESTONE_PASS "M3 EP-022 M3: ok; evidence=.agent/state/evidence/EP-022/M3"`

FALLBACK: Offer deterministic replay, match visualization, and manual editors without AI-generated patches.

COMMIT: `git add -A && git commit -m "[EP-022][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Macro Forge, Trigger Lab, and AI Debugger deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-022-macro-forge-trigger-lab-and-ai-debugger.md`
- `.agent/node-contracts/EP-022.md`
- `.agent/milestone-files/EP-022-M4.txt`
- `.agent/expected-files/EP-022.txt`
- `.agent/expected-files/EP-022.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-022-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-022`
2. `sh scripts/record-evidence.sh EP-022 M4 "EP-022 M4: ok" -- sh scripts/node-verifiers/EP-022.sh M4`
3. `sh scripts/scope-audit.sh EP-022`

EXPECT:
- `EP-022 M4: ok`
- `scope audit EP-022: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-022 MILESTONE_PASS "M4 EP-022 M4: ok; evidence=.agent/state/evidence/EP-022/M4"`

FALLBACK: Offer deterministic replay, match visualization, and manual editors without AI-generated patches.

COMMIT: `git add -A && git commit -m "[EP-022][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Macro Forge, Trigger Lab, and AI Debugger, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-022-macro-forge-trigger-lab-and-ai-debugger.md`
- `.agent/node-contracts/EP-022.md`
- `.agent/milestone-files/EP-022-M5.txt`
- `.agent/expected-files/EP-022.txt`
- `.agent/expected-files/EP-022.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-022-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-022` at `tests/live-fire/LF-022-macro-trigger-debug.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-022`
2. `sh scripts/record-evidence.sh EP-022 M5 "EP-022 M5: ok" -- sh scripts/node-verifiers/EP-022.sh M5`
3. `sh scripts/scope-audit.sh EP-022`

EXPECT:
- `EP-022 M5: ok`
- `scope audit EP-022: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-022 MILESTONE_PASS "M5 EP-022 M5: ok; evidence=.agent/state/evidence/EP-022/M5"`

FALLBACK: Offer deterministic replay, match visualization, and manual editors without AI-generated patches.

COMMIT: `git add -A && git commit -m "[EP-022][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-022` and require `node verify EP-022: ok`. Then run `sh scripts/expected-files-audit.sh EP-022`, `sh scripts/scope-audit.sh EP-022`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [x] M3: Real integration and user-visible flow
- [x] M4: Forced failures, abuse cases, performance, and operations
- [x] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

- 2026-08-28: EP-022 M1. The client build list `src/CMakeLists.txt` enumerates pane sources at lines 220-223 (.cpp) and 463-466 (.h); the power-tools pane must be wired into that exact list following the copilot/soul/autopilot/assistance pattern (WM-SRC-000146). Discovered-path amendment recorded for `src/CMakeLists.txt` (discovered path check: ok rows=1).
- 2026-08-28: EP-022 owns WM-FEAT-0106/0107/0108/0127/0161/0162 and WM-SPEC-008-R02/R07/R08 plus WM-SPEC-019-R06; AI Debugger is explicitly barred from self-certifying success and from editing gates (contract test ai-debugger-authority).
- 2026-08-28: EP-022 M4. A zero-budget replay completes before 1ms elapses, so the timeout/cancellation failure proof must use a slow script handler (2ms sleep) to genuinely overrun the 1ms budget; the crate aborts the replay with `BudgetExhausted` and records no partial run. A perf fixture that creates 2000 distinct variables trips its own 512-cap; the variable hot-path fixture reuses one key so it measures the real path without self-limiting.
- 2026-08-28: EP-022 M4. The M4 examples initially lived in a separate `wire-debugger-m4` harness crate; the scope audit rejected it as an unauthorized path. Moved the three examples into `wirecore/crates/wire-debugger/examples/` (the EP-020/EP-021 precedent) and deleted the harness crate; scope audit green.

# 13. Decision Log

- 2026-08-28 | M1 | Authorized new boundaries locked: `src/wiremudder/ui/power-tools/`, `wirecore/crates/wire-debugger/`, `compatibility/automation/`, `schemas/wiremudder/debug/`. | Node contract EP-022 authorized boundaries; static fence `.agent/expected-files/EP-022.txt`. | None considered; contract mandates these exact names. | Consequence: M2-M5 product work confined to these namespaced paths. | Reversal: contract amendment. | Affects WM-FEAT-0106/0107/0108/0127/0161/0162, WM-SPEC-008-R02/R07/R08, WM-SPEC-019-R06. | Security/privacy: SPEC-010/SPEC-022 apply; no new authority, secret access, or egress. | License/compat/perf: no new dependency; SPEC-004 budgets apply.
- 2026-08-28 | M4 | M4 examples live inside `wirecore/crates/wire-debugger/examples/`, not a separate harness crate. | Scope audit rejected `wirecore/crates/wire-debugger-m4/` as unauthorized; EP-020/EP-021 precedent places failure/security/perf examples in the owned crate. | Harness crate with its own manifest. | Consequence: M4 examples are fenced under the authorized crate boundary and compiled by the same cargo test. | Reversal: none. | Affects WM-FEAT-0106/0107/0108/0127/0161/0162. | Security/privacy: unchanged. | License/compat/perf: no new dependency.

# 14. Outcomes and Retrospective

- Changed vs expected: all changes inside the static fence plus the
  discovered-path amendment `src/CMakeLists.txt` (WM-SRC-000146,
  power-tools pane wiring).
- Source evidence: WM-SRC-000146..000149 (M1: CMakeLists pane list,
  SPEC-008 R02/R07/R08, SPEC-019 R06, wire-policy surface).
- Commands and sentinels:
  - `sh scripts/node-verifiers/EP-022.sh M1` -> `EP-022 M1: ok`
  - `sh scripts/node-verifiers/EP-022.sh M2` -> `EP-022 M2: ok` (crate 10/10 unit tests)
  - `sh scripts/node-verifiers/EP-022.sh M3` -> `EP-022 M3: ok` (real Qt6 pane harness + Rust e2e flow)
  - `sh scripts/node-verifiers/EP-022.sh M4` -> `EP-022 M4: ok` (failure 8/8, security 5/5, perf p95<=11us)
  - `sh scripts/node-verifiers/EP-022.sh M5` -> `EP-022 M5: ok` (LF-022 9 obligations true; 6 feature tests; 4 requirement tests)
  - `sh scripts/node-verify.sh EP-022` -> `node verify EP-022: ok`
- Evidence hashes: recorded in `.agent/state/evidence/EP-022/M{1..5}/`.
- Feature disposition: WM-FEAT-0106/0107/0108/0127 (required/full) and
  WM-FEAT-0161/0162 (required/ai) implemented and certified by LF-022.
- Requirement disposition: WM-SPEC-008-R02/R07/R08, WM-SPEC-019-R06 all
  automated-test green.
- Provider/platform certification: none (no provider or platform in this
  node).
- Assumptions changed: none.
- Risks: debugger state is in-memory; restart re-creates drafts/fixtures
  through normal approval flows (documented in operations runbook).
- Rollback: remove power-tools entries from `src/CMakeLists.txt`, delete
  `src/wiremudder/ui/power-tools/`, revert `wirecore/crates/wire-debugger/`
  and `schemas/wiremudder/debug/`.
- Green tag: `green/EP-022`.
- Next scheduler output: per `scripts/graph-next.sh`.
