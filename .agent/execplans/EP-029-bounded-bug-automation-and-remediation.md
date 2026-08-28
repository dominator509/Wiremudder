NODE-META-BEGIN
ID: EP-029
DEPS: EP-022,EP-028
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-029
VERIFY_SENTINEL: node verify EP-029: ok
GREEN_TAG: green/EP-029
NODE-META-END

# 1. Purpose and Big Picture

Implement evidence-backed bug intake, deduplication, reproduction, diagnosis, patch planning, independent review, canary recommendation, rollback, and terminal BLOCKED behavior for future autonomous remediation.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-029.md`.
- Own features: WM-FEAT-0133, WM-FEAT-0226, WM-FEAT-0228, WM-FEAT-0229.
- Own requirements: WM-SPEC-019-R09, WM-SPEC-025-R03.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-022, EP-028. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-029.md`
- `.agent/expected-files/EP-029.txt`
- `.agent/expected-files/EP-029.discovered.txt`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-029.txt`. The milestone fence is `.agent/milestone-files/EP-029-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-029.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-029-bounded-bug-automation-and-remediation.md`
- `.agent/node-contracts/EP-029.md`
- `.agent/expected-files/EP-029.txt`
- `.agent/expected-files/EP-029.discovered.txt`
- `.agent/milestone-files/EP-029-M1.txt`
- `.agent/milestone-files/EP-029-M2.txt`
- `.agent/milestone-files/EP-029-M3.txt`
- `.agent/milestone-files/EP-029-M4.txt`
- `.agent/milestone-files/EP-029-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-029/`
- `scripts/node-verifiers/EP-029.sh`
- `tests/live-fire/LF-029-bug-remediation-replay.sh`
- `tests/wiremudder/ep029/`
- `docs/wiremudder/bug-automation/`
- `wirecore/crates/wire-bug-automation/`
- `tools/wiremudder-bug-lab/`
- `schemas/wiremudder/bugs/`
- `maintenance/wiremudder/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-029.md`.
- Accepted specifications: SPEC-019, SPEC-022, SPEC-025, SPEC-027.
- Live-fire: `LF-029` `bug-remediation-replay`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Bounded Bug Automation and Remediation.

READ:
- `.agent/execplans/EP-029-bounded-bug-automation-and-remediation.md`
- `.agent/node-contracts/EP-029.md`
- `.agent/milestone-files/EP-029-M1.txt`
- `.agent/expected-files/EP-029.txt`
- `.agent/expected-files/EP-029.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-029-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0133, WM-FEAT-0226, WM-FEAT-0228, WM-FEAT-0229.
3. Review owned requirements: WM-SPEC-019-R09, WM-SPEC-025-R03.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-029`
2. `sh scripts/record-evidence.sh EP-029 M1 "EP-029 M1: ok" -- sh scripts/node-verifiers/EP-029.sh M1`
3. `sh scripts/scope-audit.sh EP-029`

EXPECT:
- `EP-029 M1: ok`
- `scope audit EP-029: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-029 MILESTONE_PASS "M1 EP-029 M1: ok; evidence=.agent/state/evidence/EP-029/M1"`

FALLBACK: Generate a human-reviewed diagnostic and patch plan only; do not edit production code automatically.

COMMIT: `git add -A && git commit -m "[EP-029][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Bounded Bug Automation and Remediation inside namespaced boundaries.

READ:
- `.agent/execplans/EP-029-bounded-bug-automation-and-remediation.md`
- `.agent/node-contracts/EP-029.md`
- `.agent/milestone-files/EP-029-M2.txt`
- `.agent/expected-files/EP-029.txt`
- `.agent/expected-files/EP-029.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-029-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-029`
2. `sh scripts/record-evidence.sh EP-029 M2 "EP-029 M2: ok" -- sh scripts/node-verifiers/EP-029.sh M2`
3. `sh scripts/scope-audit.sh EP-029`

EXPECT:
- `EP-029 M2: ok`
- `scope audit EP-029: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-029 MILESTONE_PASS "M2 EP-029 M2: ok; evidence=.agent/state/evidence/EP-029/M2"`

FALLBACK: Generate a human-reviewed diagnostic and patch plan only; do not edit production code automatically.

COMMIT: `git add -A && git commit -m "[EP-029][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Bounded Bug Automation and Remediation with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-029-bounded-bug-automation-and-remediation.md`
- `.agent/node-contracts/EP-029.md`
- `.agent/milestone-files/EP-029-M3.txt`
- `.agent/expected-files/EP-029.txt`
- `.agent/expected-files/EP-029.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-029-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-029`
2. `sh scripts/record-evidence.sh EP-029 M3 "EP-029 M3: ok" -- sh scripts/node-verifiers/EP-029.sh M3`
3. `sh scripts/scope-audit.sh EP-029`

EXPECT:
- `EP-029 M3: ok`
- `scope audit EP-029: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-029 MILESTONE_PASS "M3 EP-029 M3: ok; evidence=.agent/state/evidence/EP-029/M3"`

FALLBACK: Generate a human-reviewed diagnostic and patch plan only; do not edit production code automatically.

COMMIT: `git add -A && git commit -m "[EP-029][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Bounded Bug Automation and Remediation deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-029-bounded-bug-automation-and-remediation.md`
- `.agent/node-contracts/EP-029.md`
- `.agent/milestone-files/EP-029-M4.txt`
- `.agent/expected-files/EP-029.txt`
- `.agent/expected-files/EP-029.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-029-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-029`
2. `sh scripts/record-evidence.sh EP-029 M4 "EP-029 M4: ok" -- sh scripts/node-verifiers/EP-029.sh M4`
3. `sh scripts/scope-audit.sh EP-029`

EXPECT:
- `EP-029 M4: ok`
- `scope audit EP-029: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-029 MILESTONE_PASS "M4 EP-029 M4: ok; evidence=.agent/state/evidence/EP-029/M4"`

FALLBACK: Generate a human-reviewed diagnostic and patch plan only; do not edit production code automatically.

COMMIT: `git add -A && git commit -m "[EP-029][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Bounded Bug Automation and Remediation, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-029-bounded-bug-automation-and-remediation.md`
- `.agent/node-contracts/EP-029.md`
- `.agent/milestone-files/EP-029-M5.txt`
- `.agent/expected-files/EP-029.txt`
- `.agent/expected-files/EP-029.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-029-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-029` at `tests/live-fire/LF-029-bug-remediation-replay.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-029`
2. `sh scripts/record-evidence.sh EP-029 M5 "EP-029 M5: ok" -- sh scripts/node-verifiers/EP-029.sh M5`
3. `sh scripts/scope-audit.sh EP-029`

EXPECT:
- `EP-029 M5: ok`
- `scope audit EP-029: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-029 MILESTONE_PASS "M5 EP-029 M5: ok; evidence=.agent/state/evidence/EP-029/M5"`

FALLBACK: Generate a human-reviewed diagnostic and patch plan only; do not edit production code automatically.

COMMIT: `git add -A && git commit -m "[EP-029][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-029` and require `node verify EP-029: ok`. Then run `sh scripts/expected-files-audit.sh EP-029`, `sh scripts/scope-audit.sh EP-029`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [x] M3: Real integration and user-visible flow
- [x] M4: Forced failures, abuse cases, performance, and operations
- [x] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

- 2026-08-28: `complete()` initially rejected the Canary stage, yet
  SPEC-019-R09 defines DONE as reachable after a passed canary; the gate now
  accepts Review, Canary, or Rollback (commit 71f76003).
- 2026-08-28: the bug-lab CLI printed `intake: ok` before persisting state;
  with an unavailable state path it claimed success for a non-durable
  workflow. Fixed by persisting before the success sentinel (WM-SPEC-025-R05,
  commit 261acbff).
- 2026-08-28: the M4 unavailable-worker proof cannot rely on file-mode
  denial when the executor runs as root; a nonexistent parent directory is
  the user-independent failure mechanism.
- 2026-08-28: redaction markers must match both assignment forms
  (`token=`) and prose forms (`token is`) with word boundaries so
  `tokenizer` is not over-redacted (19/19 crate tests).

# 13. Decision Log

- 2026-08-28: bounded state machine with ten explicit stages and terminal
  DONE/BLOCKED (SPEC-019-R09). Evidence: crate unit suite. Alternatives:
  free-form pipeline (rejected: no bounded states). Consequence: every
  transition is auditable.
- 2026-08-28: independent review is enforced in code (reviewer != planner),
  with mandatory performance review for P0/P1 and mandatory security review
  for voice/provider/update/package/security subsystems (SPEC-019-R10).
  Evidence: review gate + unit tests. Consequence: no self-certification.
- 2026-08-28: retry policy bounded (default 3, ceiling 10) with tracked
  signatures and required idempotency keys for destructive effects
  (WM-SPEC-025-R03). Evidence: RetryPolicy + unit tests. Consequence:
  bounded failure behavior, quarantine after repeated failures.

# 14. Outcomes and Retrospective

- Changed versus expected: exactly the static fence paths plus evidence dirs;
  no inherited source path edited (discovered amendment rows=0).
- Source evidence: WM-SRC-000193..000207 (EP-029 M1).
- Commands and sentinels: `EP-029 M1: ok`, `EP-029 M2: ok`,
  `EP-029 M3: ok`, `EP-029 M4: ok`, `EP-029 M5: ok`, `LF-029: ok`
  (6/6 obligations), `node verify EP-029: ok` pending at write.
- Evidence hashes: recorded per milestone in `.agent/state/evidence/EP-029/`.
- Feature disposition: WM-FEAT-0133 (future, human-reviewed fallback only),
  WM-FEAT-0226 (required, certified), WM-FEAT-0228 (required, certified),
  WM-FEAT-0229 (required, certified).
- Requirement disposition: WM-SPEC-019-R09 and WM-SPEC-025-R03 certified by
  automated tests at the validation-matrix paths.
- Provider/platform certification: none (no external adapter in scope).
- Risks: autonomous patch planning is bounded and human-reviewed by design;
  the future feature (WM-FEAT-0133) remains research-decision-required.
- Rollback: revert EP-029 commits; no inherited path affected.
- Green tag: `green/EP-029` (after node verify).
- Next scheduler output: (after release).
