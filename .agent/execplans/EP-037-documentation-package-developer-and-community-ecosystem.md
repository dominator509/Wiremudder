NODE-META-BEGIN
ID: EP-037
DEPS: EP-010,EP-027,EP-030,EP-036
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-037
VERIFY_SENTINEL: node verify EP-037: ok
GREEN_TAG: green/EP-037
NODE-META-END

# 1. Purpose and Big Picture

Complete user, administrator, package author, importer, accessibility, privacy, troubleshooting, headless, API, build, contribution, upstream, release, and support documentation with examples that match tested contracts.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-037.md`.
- Own features: WM-FEAT-0164, WM-FEAT-0243.
- Own requirements: cross-node requirements.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-010, EP-027, EP-030, EP-036. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-037.md`
- `.agent/expected-files/EP-037.txt`
- `.agent/expected-files/EP-037.discovered.txt`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-037.txt`. The milestone fence is `.agent/milestone-files/EP-037-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-037.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-037-documentation-package-developer-and-community-ecosystem.md`
- `.agent/node-contracts/EP-037.md`
- `.agent/expected-files/EP-037.txt`
- `.agent/expected-files/EP-037.discovered.txt`
- `.agent/milestone-files/EP-037-M1.txt`
- `.agent/milestone-files/EP-037-M2.txt`
- `.agent/milestone-files/EP-037-M3.txt`
- `.agent/milestone-files/EP-037-M4.txt`
- `.agent/milestone-files/EP-037-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-037/`
- `scripts/node-verifiers/EP-037.sh`
- `tests/live-fire/LF-037-package-developer-workflow.sh`
- `tests/wiremudder/ep037/`
- `docs/wiremudder/`
- `docs/wiremudder/user/`
- `docs/wiremudder/developer/`
- `docs/wiremudder/package-author/`
- `examples/wiremudder/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-037.md`.
- Accepted specifications: SPEC-000, SPEC-008, SPEC-018, SPEC-021, SPEC-026, SPEC-028.
- Live-fire: `LF-037` `package-developer-workflow`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Documentation, Package Developer, and Community Ecosystem.

READ:
- `.agent/execplans/EP-037-documentation-package-developer-and-community-ecosystem.md`
- `.agent/node-contracts/EP-037.md`
- `.agent/milestone-files/EP-037-M1.txt`
- `.agent/expected-files/EP-037.txt`
- `.agent/expected-files/EP-037.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-037-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0164, WM-FEAT-0243.
3. Review owned requirements: cross-node requirements.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-037`
2. `sh scripts/record-evidence.sh EP-037 M1 "EP-037 M1: ok" -- sh scripts/node-verifiers/EP-037.sh M1`
3. `sh scripts/scope-audit.sh EP-037`

EXPECT:
- `EP-037 M1: ok`
- `scope audit EP-037: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-037 MILESTONE_PASS "M1 EP-037 M1: ok; evidence=.agent/state/evidence/EP-037/M1"`

FALLBACK: Publish core user, build, privacy, and troubleshooting docs and omit examples for uncertified optional capabilities.

COMMIT: `git add -A && git commit -m "[EP-037][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Documentation, Package Developer, and Community Ecosystem inside namespaced boundaries.

READ:
- `.agent/execplans/EP-037-documentation-package-developer-and-community-ecosystem.md`
- `.agent/node-contracts/EP-037.md`
- `.agent/milestone-files/EP-037-M2.txt`
- `.agent/expected-files/EP-037.txt`
- `.agent/expected-files/EP-037.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-037-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-037`
2. `sh scripts/record-evidence.sh EP-037 M2 "EP-037 M2: ok" -- sh scripts/node-verifiers/EP-037.sh M2`
3. `sh scripts/scope-audit.sh EP-037`

EXPECT:
- `EP-037 M2: ok`
- `scope audit EP-037: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-037 MILESTONE_PASS "M2 EP-037 M2: ok; evidence=.agent/state/evidence/EP-037/M2"`

FALLBACK: Publish core user, build, privacy, and troubleshooting docs and omit examples for uncertified optional capabilities.

COMMIT: `git add -A && git commit -m "[EP-037][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Documentation, Package Developer, and Community Ecosystem with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-037-documentation-package-developer-and-community-ecosystem.md`
- `.agent/node-contracts/EP-037.md`
- `.agent/milestone-files/EP-037-M3.txt`
- `.agent/expected-files/EP-037.txt`
- `.agent/expected-files/EP-037.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-037-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-037`
2. `sh scripts/record-evidence.sh EP-037 M3 "EP-037 M3: ok" -- sh scripts/node-verifiers/EP-037.sh M3`
3. `sh scripts/scope-audit.sh EP-037`

EXPECT:
- `EP-037 M3: ok`
- `scope audit EP-037: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-037 MILESTONE_PASS "M3 EP-037 M3: ok; evidence=.agent/state/evidence/EP-037/M3"`

FALLBACK: Publish core user, build, privacy, and troubleshooting docs and omit examples for uncertified optional capabilities.

COMMIT: `git add -A && git commit -m "[EP-037][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Documentation, Package Developer, and Community Ecosystem deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-037-documentation-package-developer-and-community-ecosystem.md`
- `.agent/node-contracts/EP-037.md`
- `.agent/milestone-files/EP-037-M4.txt`
- `.agent/expected-files/EP-037.txt`
- `.agent/expected-files/EP-037.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-037-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-037`
2. `sh scripts/record-evidence.sh EP-037 M4 "EP-037 M4: ok" -- sh scripts/node-verifiers/EP-037.sh M4`
3. `sh scripts/scope-audit.sh EP-037`

EXPECT:
- `EP-037 M4: ok`
- `scope audit EP-037: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-037 MILESTONE_PASS "M4 EP-037 M4: ok; evidence=.agent/state/evidence/EP-037/M4"`

FALLBACK: Publish core user, build, privacy, and troubleshooting docs and omit examples for uncertified optional capabilities.

COMMIT: `git add -A && git commit -m "[EP-037][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Documentation, Package Developer, and Community Ecosystem, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-037-documentation-package-developer-and-community-ecosystem.md`
- `.agent/node-contracts/EP-037.md`
- `.agent/milestone-files/EP-037-M5.txt`
- `.agent/expected-files/EP-037.txt`
- `.agent/expected-files/EP-037.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`
- `.agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md`

CHANGE: exact paths in `.agent/milestone-files/EP-037-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-037` at `tests/live-fire/LF-037-package-developer-workflow.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-037`
2. `sh scripts/record-evidence.sh EP-037 M5 "EP-037 M5: ok" -- sh scripts/node-verifiers/EP-037.sh M5`
3. `sh scripts/scope-audit.sh EP-037`

EXPECT:
- `EP-037 M5: ok`
- `scope audit EP-037: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-037 MILESTONE_PASS "M5 EP-037 M5: ok; evidence=.agent/state/evidence/EP-037/M5"`

FALLBACK: Publish core user, build, privacy, and troubleshooting docs and omit examples for uncertified optional capabilities.

COMMIT: `git add -A && git commit -m "[EP-037][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-037` and require `node verify EP-037: ok`. Then run `sh scripts/expected-files-audit.sh EP-037`, `sh scripts/scope-audit.sh EP-037`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [ ] M3: Real integration and user-visible flow
- [ ] M4: Forced failures, abuse cases, performance, and operations
- [ ] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

- 2026-08-28: EP-037 lease base corrected to f56c838 (HEAD at lease time); initial row copied EP-036 base by mistake — scope audit caught it immediately (correct base is a hard gate).
- 2026-08-28: M2 unit tests must be POSIX sh — process substitution `< <(...)` failed under the verifier's `sh`; rewrote with a pipe loop. Documentation surfaces verified real: all 237 required features indexed, manifest example validates against the real schema, all 13 permission names + 3 update policies documented.

# 13. Decision Log

- 2026-08-28 | EP-037 M1 | Node verifier follows the EP-036 pattern: M1 contract tests, M2 unit + boundary existence, M3 integration/e2e + design docs, M4 failure/security/perf + operations runbook, M5 LF-037 + feature tests + full audits. Evidence: scripts/node-verifiers/EP-037.sh. Alternatives: verifier checked docs by word count (rejected — empty boundary check via find -type f is stricter). Consequence: all five subcommands run real checks. Reversal: edit verifier + re-run M1..M5. Affects: WM-FEAT-0164, WM-FEAT-0243, SPEC-000/008/018/021/026/028. Security/privacy: docs only; no new authority. License: no new deps. Compatibility: new docs boundaries only. Performance: no runtime impact. Upstream: no inherited-source edits in M1 (13 source-evidence rows WM-SRC-000303..315).

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.
