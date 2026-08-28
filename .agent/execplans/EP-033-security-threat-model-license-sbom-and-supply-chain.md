NODE-META-BEGIN
ID: EP-033
DEPS: EP-006,EP-008,EP-010,EP-011,EP-014,EP-016,EP-028,EP-030,EP-032
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-033
VERIFY_SENTINEL: node verify EP-033: ok
GREEN_TAG: green/EP-033
NODE-META-END

# 1. Purpose and Big Picture

Complete threat models, secrets and dependency scans, package and asset policy, prompt-injection defenses, SBOM, provenance, GPL/source obligations, forced failures, and release-blocking security review.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-033.md`.
- Own features: cross-cutting node.
- Own requirements: WM-SPEC-001-R03, WM-SPEC-001-R08, WM-SPEC-020-R02, WM-SPEC-020-R03, WM-SPEC-020-R08, WM-SPEC-022-R06, WM-SPEC-022-R08, WM-SPEC-022-R09, WM-SPEC-028-R02, WM-SPEC-028-R03.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-006, EP-008, EP-010, EP-011, EP-014, EP-016, EP-028, EP-030, EP-032. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-033.md`
- `.agent/expected-files/EP-033.txt`
- `.agent/expected-files/EP-033.discovered.txt`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-033.txt`. The milestone fence is `.agent/milestone-files/EP-033-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-033.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-033-security-threat-model-license-sbom-and-supply-chain.md`
- `.agent/node-contracts/EP-033.md`
- `.agent/expected-files/EP-033.txt`
- `.agent/expected-files/EP-033.discovered.txt`
- `.agent/milestone-files/EP-033-M1.txt`
- `.agent/milestone-files/EP-033-M2.txt`
- `.agent/milestone-files/EP-033-M3.txt`
- `.agent/milestone-files/EP-033-M4.txt`
- `.agent/milestone-files/EP-033-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-033/`
- `scripts/node-verifiers/EP-033.sh`
- `tests/live-fire/LF-033-security-supply-chain-denial.sh`
- `tests/wiremudder/ep033/`
- `docs/wiremudder/security/`
- `security/wiremudder/`
- `sbom/wiremudder/`
- `licenses/wiremudder/`
- `tests/wiremudder/security/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-033.md`.
- Accepted specifications: SPEC-001, SPEC-020, SPEC-022, SPEC-027, SPEC-028.
- Live-fire: `LF-033` `security-supply-chain-denial`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Security, Threat Model, License, SBOM, and Supply Chain.

READ:
- `.agent/execplans/EP-033-security-threat-model-license-sbom-and-supply-chain.md`
- `.agent/node-contracts/EP-033.md`
- `.agent/milestone-files/EP-033-M1.txt`
- `.agent/expected-files/EP-033.txt`
- `.agent/expected-files/EP-033.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-033-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: cross-cutting node.
3. Review owned requirements: WM-SPEC-001-R03, WM-SPEC-001-R08, WM-SPEC-020-R02, WM-SPEC-020-R03, WM-SPEC-020-R08, WM-SPEC-022-R06, WM-SPEC-022-R08, WM-SPEC-022-R09, WM-SPEC-028-R02, WM-SPEC-028-R03.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-033`
2. `sh scripts/record-evidence.sh EP-033 M1 "EP-033 M1: ok" -- sh scripts/node-verifiers/EP-033.sh M1`
3. `sh scripts/scope-audit.sh EP-033`

EXPECT:
- `EP-033 M1: ok`
- `scope audit EP-033: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-033 MILESTONE_PASS "M1 EP-033 M1: ok; evidence=.agent/state/evidence/EP-033/M1"`

FALLBACK: Disable the affected optional capability and remove uncertified dependency or asset while preserving core text gameplay.

COMMIT: `git add -A && git commit -m "[EP-033][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Security, Threat Model, License, SBOM, and Supply Chain inside namespaced boundaries.

READ:
- `.agent/execplans/EP-033-security-threat-model-license-sbom-and-supply-chain.md`
- `.agent/node-contracts/EP-033.md`
- `.agent/milestone-files/EP-033-M2.txt`
- `.agent/expected-files/EP-033.txt`
- `.agent/expected-files/EP-033.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-033-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-033`
2. `sh scripts/record-evidence.sh EP-033 M2 "EP-033 M2: ok" -- sh scripts/node-verifiers/EP-033.sh M2`
3. `sh scripts/scope-audit.sh EP-033`

EXPECT:
- `EP-033 M2: ok`
- `scope audit EP-033: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-033 MILESTONE_PASS "M2 EP-033 M2: ok; evidence=.agent/state/evidence/EP-033/M2"`

FALLBACK: Disable the affected optional capability and remove uncertified dependency or asset while preserving core text gameplay.

COMMIT: `git add -A && git commit -m "[EP-033][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Security, Threat Model, License, SBOM, and Supply Chain with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-033-security-threat-model-license-sbom-and-supply-chain.md`
- `.agent/node-contracts/EP-033.md`
- `.agent/milestone-files/EP-033-M3.txt`
- `.agent/expected-files/EP-033.txt`
- `.agent/expected-files/EP-033.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-033-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-033`
2. `sh scripts/record-evidence.sh EP-033 M3 "EP-033 M3: ok" -- sh scripts/node-verifiers/EP-033.sh M3`
3. `sh scripts/scope-audit.sh EP-033`

EXPECT:
- `EP-033 M3: ok`
- `scope audit EP-033: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-033 MILESTONE_PASS "M3 EP-033 M3: ok; evidence=.agent/state/evidence/EP-033/M3"`

FALLBACK: Disable the affected optional capability and remove uncertified dependency or asset while preserving core text gameplay.

COMMIT: `git add -A && git commit -m "[EP-033][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Security, Threat Model, License, SBOM, and Supply Chain deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-033-security-threat-model-license-sbom-and-supply-chain.md`
- `.agent/node-contracts/EP-033.md`
- `.agent/milestone-files/EP-033-M4.txt`
- `.agent/expected-files/EP-033.txt`
- `.agent/expected-files/EP-033.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-033-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-033`
2. `sh scripts/record-evidence.sh EP-033 M4 "EP-033 M4: ok" -- sh scripts/node-verifiers/EP-033.sh M4`
3. `sh scripts/scope-audit.sh EP-033`

EXPECT:
- `EP-033 M4: ok`
- `scope audit EP-033: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-033 MILESTONE_PASS "M4 EP-033 M4: ok; evidence=.agent/state/evidence/EP-033/M4"`

FALLBACK: Disable the affected optional capability and remove uncertified dependency or asset while preserving core text gameplay.

COMMIT: `git add -A && git commit -m "[EP-033][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Security, Threat Model, License, SBOM, and Supply Chain, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-033-security-threat-model-license-sbom-and-supply-chain.md`
- `.agent/node-contracts/EP-033.md`
- `.agent/milestone-files/EP-033-M5.txt`
- `.agent/expected-files/EP-033.txt`
- `.agent/expected-files/EP-033.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-033-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-033` at `tests/live-fire/LF-033-security-supply-chain-denial.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-033`
2. `sh scripts/record-evidence.sh EP-033 M5 "EP-033 M5: ok" -- sh scripts/node-verifiers/EP-033.sh M5`
3. `sh scripts/scope-audit.sh EP-033`

EXPECT:
- `EP-033 M5: ok`
- `scope audit EP-033: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-033 MILESTONE_PASS "M5 EP-033 M5: ok; evidence=.agent/state/evidence/EP-033/M5"`

FALLBACK: Disable the affected optional capability and remove uncertified dependency or asset while preserving core text gameplay.

COMMIT: `git add -A && git commit -m "[EP-033][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-033` and require `node verify EP-033: ok`. Then run `sh scripts/expected-files-audit.sh EP-033`, `sh scripts/scope-audit.sh EP-033`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock — commit c279fbdd; verifier EP-033 M1: ok; 3 contract tests; evidence WM-SRC-000243..000254
- [x] M2: Core behavior and deterministic invariants — commit b2d6a16; wiremudder-security crate 33/33 tests, zero warnings; verifier EP-033 M2: ok
- [x] M3: Real integration and user-visible flow — commit 18e255c; real repo inventory/SBOM/license artifacts; hostile-import e2e; verifier EP-033 M3: ok
- [x] M4: Forced failures, abuse cases, performance, and operations — commit a0c5b40; failure/denial/security/supply-chain tests; perf p95=6us budget=1000us; runbook; verifier EP-033 M4: ok
- [x] M5: Live-fire, evidence closure, and green tag readiness — LF-033 7/7 certified; 10 requirement tests; verifier EP-033 M5: ok

# 12. Surprises and Discoveries

Append dated evidence-backed discoveries. Speculation is not a discovery.

- 2026-08-28: GNU grep 3.11 basic regex does not treat `\t` as a tab; requirement test-path extraction must use awk `-F'\t'` field matching instead of `grep "^$r\t"` (EP-033 M5 verifier fix).
- 2026-08-28: The EP-003 hostile-input corpus intentionally contains AWS-documentation example key material; the shared repo secrets gate must exclude those two sanitize-test fixtures, whose own tests prove the strings are redacted before any user-facing output.
- 2026-08-28: Display-layer redaction masks credential-like literals in tool output; secrets-scan tests must assemble long keys at runtime (printf concatenation) so the scanner observes full-length secrets.

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

- 2026-08-28: M2 core implemented as a deterministic Rust crate `security/wiremudder/` with CLI (scan-secrets, check-injection, sbom, threat-model, lanes, release-block). Evidence: crate 33/33 tests, zero warnings. Alternatives: Python tooling rejected (repo is Rust-native, deterministic typed rules). Consequence: real SBOM/license artifacts generated from the actual .gitmodules. Affects: WM-SPEC-001-R08, WM-SPEC-020-R02/R03/R08, WM-SPEC-022-R06/R08/R09, WM-SPEC-028-R02/R03. No inherited source edited.
- 2026-08-28: Prompt-injection markers are matched after quote-stripping normalization so encoded attempts (curly apostrophes splitting a marker) are denied as Encoded; the direct marker set also covers "disregard all previous instructions". Evidence: prompt-injection-suite 6/6. Security impact: fail-closed denial surface.
- 2026-08-28: Threat-model boundary coverage uses explicit `covers` lists on mitigations rather than name-substring matching, which is fragile. Evidence: fixture threat-model-session-bridge.json validates. Consequence: unambiguous coverage; every boundary must name its mitigation.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

- Changed vs expected: all changes inside the EP-033 static fence; 0 discovered-path rows; scope audit changed=53; expected-files audit ok (21 paths).
- Source evidence: WM-SRC-000243..000254 (12 rows) appended in M1.
- Commands and sentinels: `node verify EP-033: ok`; `EP-033 M1..M5: ok`; `LF-033: ok checks=7/7`; perf `p50=3us p95=6us max=19us budget=1000us`; contract/scope/expected-files audits ok.
- Feature disposition: cross-cutting node — no owned feature rows; coverage proven via owned requirements.
- Requirement disposition: WM-SPEC-001-R03/R08, WM-SPEC-020-R02/R03/R08, WM-SPEC-022-R06/R08/R09, WM-SPEC-028-R02/R03 all closed with tests at the matrix test_paths (10/10).
- Provider/platform certification: none claimed (no external adapter).
- Assumptions changed: none.
- Risks: residual protocol-ambiguity and novel-injection risks documented in the threat model; secret-shaped examples confined to test zones.
- Rollback: node is additive; remove security/, sbom/, licenses/ boundaries to disable; never cross a completed green tag.
- Green tag: green/EP-033 (pending node verify).
- Next scheduler output: to be read after lease release.
