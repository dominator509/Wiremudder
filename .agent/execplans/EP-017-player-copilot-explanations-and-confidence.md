NODE-META-BEGIN
ID: EP-017
DEPS: EP-008,EP-016
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-017
VERIFY_SENTINEL: node verify EP-017: ok
GREEN_TAG: green/EP-017
NODE-META-END

# 1. Purpose and Big Picture

Implement suggestion-only Player Copilot, cited Why explanations, calibrated confidence, uncertainty, cancellation, and visible context/privacy/cost disclosures.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-017.md`.
- Own features: WM-FEAT-0039, WM-FEAT-0040, WM-FEAT-0046, WM-FEAT-0047.
- Own requirements: WM-SPEC-014-R01, WM-SPEC-014-R03, WM-SPEC-014-R04, WM-SPEC-014-R08, WM-SPEC-014-R09.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-008, EP-016. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-017.md`
- `.agent/expected-files/EP-017.txt`
- `.agent/expected-files/EP-017.discovered.txt`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-017.txt`. The milestone fence is `.agent/milestone-files/EP-017-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-017.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-017-player-copilot-explanations-and-confidence.md`
- `.agent/node-contracts/EP-017.md`
- `.agent/expected-files/EP-017.txt`
- `.agent/expected-files/EP-017.discovered.txt`
- `.agent/milestone-files/EP-017-M1.txt`
- `.agent/milestone-files/EP-017-M2.txt`
- `.agent/milestone-files/EP-017-M3.txt`
- `.agent/milestone-files/EP-017-M4.txt`
- `.agent/milestone-files/EP-017-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-017/`
- `scripts/node-verifiers/EP-017.sh`
- `tests/live-fire/LF-017-copilot-suggestion-explanation.sh`
- `tests/wiremudder/ep017/`
- `docs/wiremudder/copilot/`
- `wirecore/crates/wire-copilot/`
- `src/wiremudder/ui/copilot/`
- `schemas/wiremudder/copilot/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-017.md`.
- Accepted specifications: SPEC-009, SPEC-013, SPEC-014.
- Live-fire: `LF-017` `copilot-suggestion-explanation`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Player Copilot, Explanations, and Confidence.

READ:
- `.agent/execplans/EP-017-player-copilot-explanations-and-confidence.md`
- `.agent/node-contracts/EP-017.md`
- `.agent/milestone-files/EP-017-M1.txt`
- `.agent/expected-files/EP-017.txt`
- `.agent/expected-files/EP-017.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`

CHANGE: exact paths in `.agent/milestone-files/EP-017-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0039, WM-FEAT-0040, WM-FEAT-0046, WM-FEAT-0047.
3. Review owned requirements: WM-SPEC-014-R01, WM-SPEC-014-R03, WM-SPEC-014-R04, WM-SPEC-014-R08, WM-SPEC-014-R09.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-017`
2. `sh scripts/record-evidence.sh EP-017 M1 "EP-017 M1: ok" -- sh scripts/node-verifiers/EP-017.sh M1`
3. `sh scripts/scope-audit.sh EP-017`

EXPECT:
- `EP-017 M1: ok`
- `scope audit EP-017: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-017 MILESTONE_PASS "M1 EP-017 M1: ok; evidence=.agent/state/evidence/EP-017/M1"`

FALLBACK: Provide deterministic context and rule-based hints only, clearly labeled, until a provider passes quality and privacy evaluation.

COMMIT: `git add -A && git commit -m "[EP-017][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Player Copilot, Explanations, and Confidence inside namespaced boundaries.

READ:
- `.agent/execplans/EP-017-player-copilot-explanations-and-confidence.md`
- `.agent/node-contracts/EP-017.md`
- `.agent/milestone-files/EP-017-M2.txt`
- `.agent/expected-files/EP-017.txt`
- `.agent/expected-files/EP-017.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`

CHANGE: exact paths in `.agent/milestone-files/EP-017-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-017`
2. `sh scripts/record-evidence.sh EP-017 M2 "EP-017 M2: ok" -- sh scripts/node-verifiers/EP-017.sh M2`
3. `sh scripts/scope-audit.sh EP-017`

EXPECT:
- `EP-017 M2: ok`
- `scope audit EP-017: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-017 MILESTONE_PASS "M2 EP-017 M2: ok; evidence=.agent/state/evidence/EP-017/M2"`

FALLBACK: Provide deterministic context and rule-based hints only, clearly labeled, until a provider passes quality and privacy evaluation.

COMMIT: `git add -A && git commit -m "[EP-017][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Player Copilot, Explanations, and Confidence with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-017-player-copilot-explanations-and-confidence.md`
- `.agent/node-contracts/EP-017.md`
- `.agent/milestone-files/EP-017-M3.txt`
- `.agent/expected-files/EP-017.txt`
- `.agent/expected-files/EP-017.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`

CHANGE: exact paths in `.agent/milestone-files/EP-017-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-017`
2. `sh scripts/record-evidence.sh EP-017 M3 "EP-017 M3: ok" -- sh scripts/node-verifiers/EP-017.sh M3`
3. `sh scripts/scope-audit.sh EP-017`

EXPECT:
- `EP-017 M3: ok`
- `scope audit EP-017: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-017 MILESTONE_PASS "M3 EP-017 M3: ok; evidence=.agent/state/evidence/EP-017/M3"`

FALLBACK: Provide deterministic context and rule-based hints only, clearly labeled, until a provider passes quality and privacy evaluation.

COMMIT: `git add -A && git commit -m "[EP-017][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Player Copilot, Explanations, and Confidence deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-017-player-copilot-explanations-and-confidence.md`
- `.agent/node-contracts/EP-017.md`
- `.agent/milestone-files/EP-017-M4.txt`
- `.agent/expected-files/EP-017.txt`
- `.agent/expected-files/EP-017.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`

CHANGE: exact paths in `.agent/milestone-files/EP-017-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-017`
2. `sh scripts/record-evidence.sh EP-017 M4 "EP-017 M4: ok" -- sh scripts/node-verifiers/EP-017.sh M4`
3. `sh scripts/scope-audit.sh EP-017`

EXPECT:
- `EP-017 M4: ok`
- `scope audit EP-017: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-017 MILESTONE_PASS "M4 EP-017 M4: ok; evidence=.agent/state/evidence/EP-017/M4"`

FALLBACK: Provide deterministic context and rule-based hints only, clearly labeled, until a provider passes quality and privacy evaluation.

COMMIT: `git add -A && git commit -m "[EP-017][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Player Copilot, Explanations, and Confidence, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-017-player-copilot-explanations-and-confidence.md`
- `.agent/node-contracts/EP-017.md`
- `.agent/milestone-files/EP-017-M5.txt`
- `.agent/expected-files/EP-017.txt`
- `.agent/expected-files/EP-017.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md`
- `.agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md`

CHANGE: exact paths in `.agent/milestone-files/EP-017-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-017` at `tests/live-fire/LF-017-copilot-suggestion-explanation.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-017`
2. `sh scripts/record-evidence.sh EP-017 M5 "EP-017 M5: ok" -- sh scripts/node-verifiers/EP-017.sh M5`
3. `sh scripts/scope-audit.sh EP-017`

EXPECT:
- `EP-017 M5: ok`
- `scope audit EP-017: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-017 MILESTONE_PASS "M5 EP-017 M5: ok; evidence=.agent/state/evidence/EP-017/M5"`

FALLBACK: Provide deterministic context and rule-based hints only, clearly labeled, until a provider passes quality and privacy evaluation.

COMMIT: `git add -A && git commit -m "[EP-017][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-017` and require `node verify EP-017: ok`. Then run `sh scripts/expected-files-audit.sh EP-017`, `sh scripts/scope-audit.sh EP-017`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [ ] M2: Core behavior and deterministic invariants
- [ ] M3: Real integration and user-visible flow
- [ ] M4: Forced failures, abuse cases, performance, and operations
- [ ] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

Append dated evidence-backed discoveries. Speculation is not a discovery.

# 13. Decision Log

- 2026-08-27 (M1, CORRECTED): Player Copilot lives in a new standalone crate
  (wirecore/crates/wire-copilot) plus a new Qt UI boundary
  (src/wiremudder/ui/copilot) following the inherited pane pattern
  (terminal_boundary.h precedent, WM-SRC-000114). The copilot UI is REAL only
  if compiled into the client: src/CMakeLists.txt set(mudlet_SRCS) is the
  explicit build list and the smallest evidence-backed inherited integration
  patch (WM-SRC-000118). Authorized via discovered-path amendment EP-017 ->
  src/CMakeLists.txt; contract test build-integration.sh fails if a copilot
  UI source exists without a build entry. No other inherited file is edited.
- 2026-08-27 (M1): the copilot consumes approved context only (EP-015
  ContextCapsule) and routes through EP-016; it is suggestion-only and
  command-capable output enters SPEC-009 (contract test enforces the
  obligation).

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.
