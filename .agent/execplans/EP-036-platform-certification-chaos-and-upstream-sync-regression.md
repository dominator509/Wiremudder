NODE-META-BEGIN
ID: EP-036
DEPS: EP-003,EP-011,EP-012,EP-023,EP-035
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-036
VERIFY_SENTINEL: node verify EP-036: ok
GREEN_TAG: green/EP-036
NODE-META-END

# 1. Purpose and Big Picture

Certify clean Windows, macOS, and Linux flows; exercise dependency, process, network, storage, provider, package, update, and resource faults; and prove an upstream sync does not break contracts.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-036.md`.
- Own features: WM-FEAT-0159, WM-FEAT-0242.
- Own requirements: WM-SPEC-019-R02, WM-SPEC-027-R08.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-003, EP-011, EP-012, EP-023, EP-035. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-036.md`
- `.agent/expected-files/EP-036.txt`
- `.agent/expected-files/EP-036.discovered.txt`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-036.txt`. The milestone fence is `.agent/milestone-files/EP-036-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-036.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-036-platform-certification-chaos-and-upstream-sync-regression.md`
- `.agent/node-contracts/EP-036.md`
- `.agent/expected-files/EP-036.txt`
- `.agent/expected-files/EP-036.discovered.txt`
- `.agent/milestone-files/EP-036-M1.txt`
- `.agent/milestone-files/EP-036-M2.txt`
- `.agent/milestone-files/EP-036-M3.txt`
- `.agent/milestone-files/EP-036-M4.txt`
- `.agent/milestone-files/EP-036-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-036/`
- `scripts/node-verifiers/EP-036.sh`
- `tests/live-fire/LF-036-platform-chaos-matrix.sh`
- `tests/wiremudder/ep036/`
- `docs/wiremudder/certification/`
- `tests/wiremudder/platform/`
- `tests/wiremudder/chaos/`
- `compatibility/platform/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-036.md`.
- Accepted specifications: SPEC-001, SPEC-005, SPEC-006, SPEC-017, SPEC-021, SPEC-027, SPEC-028.
- Live-fire: `LF-036` `platform-chaos-matrix`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Platform Certification, Chaos, and Upstream Sync Regression.

READ:
- `.agent/execplans/EP-036-platform-certification-chaos-and-upstream-sync-regression.md`
- `.agent/node-contracts/EP-036.md`
- `.agent/milestone-files/EP-036-M1.txt`
- `.agent/expected-files/EP-036.txt`
- `.agent/expected-files/EP-036.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-036-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0159, WM-FEAT-0242.
3. Review owned requirements: WM-SPEC-019-R02, WM-SPEC-027-R08.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-036`
2. `sh scripts/record-evidence.sh EP-036 M1 "EP-036 M1: ok" -- sh scripts/node-verifiers/EP-036.sh M1`
3. `sh scripts/scope-audit.sh EP-036`

EXPECT:
- `EP-036 M1: ok`
- `scope audit EP-036: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-036 MILESTONE_PASS "M1 EP-036 M1: ok; evidence=.agent/state/evidence/EP-036/M1"`

FALLBACK: Limit the first certified release to platforms with complete green evidence and keep others development-only and unadvertised.

COMMIT: `git add -A && git commit -m "[EP-036][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Platform Certification, Chaos, and Upstream Sync Regression inside namespaced boundaries.

READ:
- `.agent/execplans/EP-036-platform-certification-chaos-and-upstream-sync-regression.md`
- `.agent/node-contracts/EP-036.md`
- `.agent/milestone-files/EP-036-M2.txt`
- `.agent/expected-files/EP-036.txt`
- `.agent/expected-files/EP-036.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-036-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-036`
2. `sh scripts/record-evidence.sh EP-036 M2 "EP-036 M2: ok" -- sh scripts/node-verifiers/EP-036.sh M2`
3. `sh scripts/scope-audit.sh EP-036`

EXPECT:
- `EP-036 M2: ok`
- `scope audit EP-036: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-036 MILESTONE_PASS "M2 EP-036 M2: ok; evidence=.agent/state/evidence/EP-036/M2"`

FALLBACK: Limit the first certified release to platforms with complete green evidence and keep others development-only and unadvertised.

COMMIT: `git add -A && git commit -m "[EP-036][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Platform Certification, Chaos, and Upstream Sync Regression with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-036-platform-certification-chaos-and-upstream-sync-regression.md`
- `.agent/node-contracts/EP-036.md`
- `.agent/milestone-files/EP-036-M3.txt`
- `.agent/expected-files/EP-036.txt`
- `.agent/expected-files/EP-036.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-036-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-036`
2. `sh scripts/record-evidence.sh EP-036 M3 "EP-036 M3: ok" -- sh scripts/node-verifiers/EP-036.sh M3`
3. `sh scripts/scope-audit.sh EP-036`

EXPECT:
- `EP-036 M3: ok`
- `scope audit EP-036: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-036 MILESTONE_PASS "M3 EP-036 M3: ok; evidence=.agent/state/evidence/EP-036/M3"`

FALLBACK: Limit the first certified release to platforms with complete green evidence and keep others development-only and unadvertised.

COMMIT: `git add -A && git commit -m "[EP-036][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Platform Certification, Chaos, and Upstream Sync Regression deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-036-platform-certification-chaos-and-upstream-sync-regression.md`
- `.agent/node-contracts/EP-036.md`
- `.agent/milestone-files/EP-036-M4.txt`
- `.agent/expected-files/EP-036.txt`
- `.agent/expected-files/EP-036.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-036-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-036`
2. `sh scripts/record-evidence.sh EP-036 M4 "EP-036 M4: ok" -- sh scripts/node-verifiers/EP-036.sh M4`
3. `sh scripts/scope-audit.sh EP-036`

EXPECT:
- `EP-036 M4: ok`
- `scope audit EP-036: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-036 MILESTONE_PASS "M4 EP-036 M4: ok; evidence=.agent/state/evidence/EP-036/M4"`

FALLBACK: Limit the first certified release to platforms with complete green evidence and keep others development-only and unadvertised.

COMMIT: `git add -A && git commit -m "[EP-036][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Platform Certification, Chaos, and Upstream Sync Regression, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-036-platform-certification-chaos-and-upstream-sync-regression.md`
- `.agent/node-contracts/EP-036.md`
- `.agent/milestone-files/EP-036-M5.txt`
- `.agent/expected-files/EP-036.txt`
- `.agent/expected-files/EP-036.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-036-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-036` at `tests/live-fire/LF-036-platform-chaos-matrix.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-036`
2. `sh scripts/record-evidence.sh EP-036 M5 "EP-036 M5: ok" -- sh scripts/node-verifiers/EP-036.sh M5`
3. `sh scripts/scope-audit.sh EP-036`

EXPECT:
- `EP-036 M5: ok`
- `scope audit EP-036: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-036 MILESTONE_PASS "M5 EP-036 M5: ok; evidence=.agent/state/evidence/EP-036/M5"`

FALLBACK: Limit the first certified release to platforms with complete green evidence and keep others development-only and unadvertised.

COMMIT: `git add -A && git commit -m "[EP-036][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-036` and require `node verify EP-036: ok`. Then run `sh scripts/expected-files-audit.sh EP-036`, `sh scripts/scope-audit.sh EP-036`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock — commit 20e7685; verifier EP-036 M1: ok; 3 contract tests; evidence WM-SRC-000290..000301
- [x] M2: Core behavior and deterministic invariants — commit f2d2938; platform certification + chaos fault injection; compatibility matrix; verifier EP-036 M2: ok
- [x] M3: Real integration and user-visible flow — commit cdc484c; certification harness integration; e2e outcome; design doc; verifier EP-036 M3: ok
- [x] M4: Forced failures, abuse cases, performance, and operations — commit f2a191a; 7 forced failures; security surface; perf updater p95=67us release p95=177us budget=1000us; runbook; verifier EP-036 M4: ok
- [x] M5: Live-fire, evidence closure, and green tag readiness — LF-036 8/8 certified; 2 requirement tests; event schema extended for WM-SPEC-019-R02 (sanctioned fence amendment); verifier EP-036 M5: ok
- [ ] M2: Core behavior and deterministic invariants
- [ ] M3: Real integration and user-visible flow
- [ ] M4: Forced failures, abuse cases, performance, and operations
- [ ] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

Append dated evidence-backed discoveries. Speculation is not a discovery.

- 2026-08-28: The canonical event schema (EP-028) omitted app/platform/privacy/voice/renderer/redaction fields required by owned requirement WM-SPEC-019-R02; the schema was extended and the path added to the EP-036 static fence with a same-commit authority hash refresh (sanctioned amendment, EP-028 precedent).
- 2026-08-28: Platform certification is honest: Linux is certified with real evidence; Windows/macOS remain development-only until matching evidence exists (SPEC-027-R08 fallback).

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

- 2026-08-28: M1 — platform certification and chaos are test-and-evidence boundaries (`tests/wiremudder/platform/`, `tests/wiremudder/chaos/`, `compatibility/platform/`, `docs/wiremudder/certification/`); no inherited source is edited. Certification evidence is real controlled runs on the Linux host plus documented cross-platform evidence requirements (SPEC-027-R08). Alternative (claiming Windows/macOS certification without evidence) rejected: violates the reality gate. Consequence: platform claims are bounded by evidence; the fallback keeps uncertified platforms development-only. Affects WM-FEAT-0159/0242 and WM-SPEC-019-R02, WM-SPEC-027-R08.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.
