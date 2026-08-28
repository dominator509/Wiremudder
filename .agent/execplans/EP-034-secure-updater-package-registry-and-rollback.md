NODE-META-BEGIN
ID: EP-034
DEPS: EP-010,EP-033
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-034
VERIFY_SENTINEL: node verify EP-034: ok
GREEN_TAG: green/EP-034
NODE-META-END

# 1. Purpose and Big Picture

Implement signed core and asset manifests, separate update lanes, channel policy, resumable downloads, permission review, health confirmation, migration safety, staged rollout metadata, quarantine, and rollback.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-034.md`.
- Own features: WM-FEAT-0102, WM-FEAT-0230, WM-FEAT-0231, WM-FEAT-0232, WM-FEAT-0233, WM-FEAT-0234, WM-FEAT-0235, WM-FEAT-0236, WM-FEAT-0237, WM-FEAT-0238, WM-FEAT-0240.
- Own requirements: WM-SPEC-020-R04, WM-SPEC-020-R06, WM-SPEC-020-R10, WM-SPEC-028-R04, WM-SPEC-028-R08.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-010, EP-033. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-034.md`
- `.agent/expected-files/EP-034.txt`
- `.agent/expected-files/EP-034.discovered.txt`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-034.txt`. The milestone fence is `.agent/milestone-files/EP-034-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-034.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-034-secure-updater-package-registry-and-rollback.md`
- `.agent/node-contracts/EP-034.md`
- `.agent/expected-files/EP-034.txt`
- `.agent/expected-files/EP-034.discovered.txt`
- `.agent/milestone-files/EP-034-M1.txt`
- `.agent/milestone-files/EP-034-M2.txt`
- `.agent/milestone-files/EP-034-M3.txt`
- `.agent/milestone-files/EP-034-M4.txt`
- `.agent/milestone-files/EP-034-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-034/`
- `scripts/node-verifiers/EP-034.sh`
- `tests/live-fire/LF-034-signed-update-rollback.sh`
- `tests/wiremudder/ep034/`
- `docs/wiremudder/updater/`
- `src/wiremudder/updater/`
- `wirecore/crates/wire-updater/`
- `schemas/wiremudder/update/`
- `tools/update-fixtures/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-034.md`.
- Accepted specifications: SPEC-010, SPEC-020, SPEC-022, SPEC-025.
- Live-fire: `LF-034` `signed-update-rollback`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Secure Updater, Package Registry, and Rollback.

READ:
- `.agent/execplans/EP-034-secure-updater-package-registry-and-rollback.md`
- `.agent/node-contracts/EP-034.md`
- `.agent/milestone-files/EP-034-M1.txt`
- `.agent/expected-files/EP-034.txt`
- `.agent/expected-files/EP-034.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-034-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0102, WM-FEAT-0230, WM-FEAT-0231, WM-FEAT-0232, WM-FEAT-0233, WM-FEAT-0234, WM-FEAT-0235, WM-FEAT-0236, WM-FEAT-0237, WM-FEAT-0238, WM-FEAT-0240.
3. Review owned requirements: WM-SPEC-020-R04, WM-SPEC-020-R06, WM-SPEC-020-R10, WM-SPEC-028-R04, WM-SPEC-028-R08.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-034`
2. `sh scripts/record-evidence.sh EP-034 M1 "EP-034 M1: ok" -- sh scripts/node-verifiers/EP-034.sh M1`
3. `sh scripts/scope-audit.sh EP-034`

EXPECT:
- `EP-034 M1: ok`
- `scope audit EP-034: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-034 MILESTONE_PASS "M1 EP-034 M1: ok; evidence=.agent/state/evidence/EP-034/M1"`

FALLBACK: Ship manual, checksum-verified releases with the updater disabled until signing and rollback infrastructure is certified.

COMMIT: `git add -A && git commit -m "[EP-034][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Secure Updater, Package Registry, and Rollback inside namespaced boundaries.

READ:
- `.agent/execplans/EP-034-secure-updater-package-registry-and-rollback.md`
- `.agent/node-contracts/EP-034.md`
- `.agent/milestone-files/EP-034-M2.txt`
- `.agent/expected-files/EP-034.txt`
- `.agent/expected-files/EP-034.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-034-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-034`
2. `sh scripts/record-evidence.sh EP-034 M2 "EP-034 M2: ok" -- sh scripts/node-verifiers/EP-034.sh M2`
3. `sh scripts/scope-audit.sh EP-034`

EXPECT:
- `EP-034 M2: ok`
- `scope audit EP-034: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-034 MILESTONE_PASS "M2 EP-034 M2: ok; evidence=.agent/state/evidence/EP-034/M2"`

FALLBACK: Ship manual, checksum-verified releases with the updater disabled until signing and rollback infrastructure is certified.

COMMIT: `git add -A && git commit -m "[EP-034][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Secure Updater, Package Registry, and Rollback with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-034-secure-updater-package-registry-and-rollback.md`
- `.agent/node-contracts/EP-034.md`
- `.agent/milestone-files/EP-034-M3.txt`
- `.agent/expected-files/EP-034.txt`
- `.agent/expected-files/EP-034.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-034-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-034`
2. `sh scripts/record-evidence.sh EP-034 M3 "EP-034 M3: ok" -- sh scripts/node-verifiers/EP-034.sh M3`
3. `sh scripts/scope-audit.sh EP-034`

EXPECT:
- `EP-034 M3: ok`
- `scope audit EP-034: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-034 MILESTONE_PASS "M3 EP-034 M3: ok; evidence=.agent/state/evidence/EP-034/M3"`

FALLBACK: Ship manual, checksum-verified releases with the updater disabled until signing and rollback infrastructure is certified.

COMMIT: `git add -A && git commit -m "[EP-034][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Secure Updater, Package Registry, and Rollback deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-034-secure-updater-package-registry-and-rollback.md`
- `.agent/node-contracts/EP-034.md`
- `.agent/milestone-files/EP-034-M4.txt`
- `.agent/expected-files/EP-034.txt`
- `.agent/expected-files/EP-034.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-034-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-034`
2. `sh scripts/record-evidence.sh EP-034 M4 "EP-034 M4: ok" -- sh scripts/node-verifiers/EP-034.sh M4`
3. `sh scripts/scope-audit.sh EP-034`

EXPECT:
- `EP-034 M4: ok`
- `scope audit EP-034: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-034 MILESTONE_PASS "M4 EP-034 M4: ok; evidence=.agent/state/evidence/EP-034/M4"`

FALLBACK: Ship manual, checksum-verified releases with the updater disabled until signing and rollback infrastructure is certified.

COMMIT: `git add -A && git commit -m "[EP-034][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Secure Updater, Package Registry, and Rollback, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-034-secure-updater-package-registry-and-rollback.md`
- `.agent/node-contracts/EP-034.md`
- `.agent/milestone-files/EP-034-M5.txt`
- `.agent/expected-files/EP-034.txt`
- `.agent/expected-files/EP-034.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-025-error-handling-recovery-and-compensation.md`

CHANGE: exact paths in `.agent/milestone-files/EP-034-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-034` at `tests/live-fire/LF-034-signed-update-rollback.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-034`
2. `sh scripts/record-evidence.sh EP-034 M5 "EP-034 M5: ok" -- sh scripts/node-verifiers/EP-034.sh M5`
3. `sh scripts/scope-audit.sh EP-034`

EXPECT:
- `EP-034 M5: ok`
- `scope audit EP-034: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-034 MILESTONE_PASS "M5 EP-034 M5: ok; evidence=.agent/state/evidence/EP-034/M5"`

FALLBACK: Ship manual, checksum-verified releases with the updater disabled until signing and rollback infrastructure is certified.

COMMIT: `git add -A && git commit -m "[EP-034][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-034` and require `node verify EP-034: ok`. Then run `sh scripts/expected-files-audit.sh EP-034`, `sh scripts/scope-audit.sh EP-034`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock -- commit 02cc6e31; verifier EP-034 M1: ok; 4 contract tests; evidence WM-SRC-000255..000275; discovered amendment src/CMakeLists.txt (WM-SRC-000262)
- [x] M2: Core behavior and deterministic invariants -- commit 2dc543e; wire-updater crate 17/17 tests zero warnings; oracle CLI; update-fixtures tool; C++ boundary; schema; verifier EP-034 M2: ok
- [x] M3: Real integration and user-visible flow -- commit 2cf25de; CMake wiring; Qt6 boundary compile zero warnings; e2e signed flow; design doc; verifier EP-034 M3: ok
- [x] M4: Forced failures, abuse cases, performance, and operations -- commit ec13daa; 11 forced failures + 5 denials; security surface; perf p50=53us p95=69us budget=1000us; runbook; verifier EP-034 M4: ok
- [x] M5: Live-fire, evidence closure, and green tag readiness -- LF-034 10/10 certified; 5 requirement tests; verifier EP-034 M5: ok
- [ ] M2: Core behavior and deterministic invariants
- [ ] M3: Real integration and user-visible flow
- [ ] M4: Forced failures, abuse cases, performance, and operations
- [ ] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

Append dated evidence-backed discoveries. Speculation is not a discovery.

- 2026-08-28: ed25519-dalek 3.0 pins rand_core 0.10, which has no OsRng; key generation uses getrandom 0.3 seeding directly. In-crate tests use deterministic seeds (no RNG), keeping the unit suite reproducible.
- 2026-08-28: Requirement tests live one directory deeper than milestone suites; `cd` depth is 5 (`../../../../..`), not 4 (EP-034 M5 fix, matches EP-033 lesson).
- 2026-08-28: Oracle typed denials print to stdout with exit 0 by design (fail-closed via output); only hard errors (missing file, invalid key hex, unknown subcommand) exit nonzero. Forced-failure tests assert denial text, not exit codes.

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

- 2026-08-28: M1 -- updater boundary is a namespaced Qt model-side boundary at `src/wiremudder/updater/` wired into `mudlet_SRCS` via the USE_UPDATER-adjacent source list, exactly beside owned panes (EP-030/031 precedent, WM-SRC-000262). Alternative (editing inherited `src/updater.cpp` directly) rejected: violates the inherited-source rule; the inherited dblsqd surface stays untouched and the new signed-update core lives in `wirecore/crates/wire-updater/` with schema at `schemas/wiremudder/update/` and real fixtures at `tools/update-fixtures/`. Consequence: manual gameplay is preserved; rollback is a single `git checkout -- src/CMakeLists.txt`. Affects WM-FEAT-0102/0230..0238/0240 and WM-SPEC-020-R04/R06/R10, WM-SPEC-028-R04/R08. Security: no signing keys enter agent env (SPEC-020-R09).

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.
