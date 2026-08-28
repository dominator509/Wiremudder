NODE-META-BEGIN
ID: EP-027
DEPS: EP-006,EP-012,EP-016
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-027
VERIFY_SENTINEL: node verify EP-027: ok
GREEN_TAG: green/EP-027
NODE-META-END

# 1. Purpose and Big Picture

Implement help bubbles, safe defaults, validation/privacy guidance, local Help Knowledge Index, Ask WireMudder AI, world capability onboarding, CLI parity, and opt-in source indexing without mutation authority.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-027.md`.
- Own features: WM-FEAT-0109, WM-FEAT-0111, WM-FEAT-0112, WM-FEAT-0187, WM-FEAT-0213, WM-FEAT-0214, WM-FEAT-0215, WM-FEAT-0216, WM-FEAT-0217, WM-FEAT-0218, WM-FEAT-0219.
- Own requirements: WM-SPEC-007-R09, WM-SPEC-018-R04, WM-SPEC-018-R05, WM-SPEC-018-R09.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-006, EP-012, EP-016. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-027.md`
- `.agent/expected-files/EP-027.txt`
- `.agent/expected-files/EP-027.discovered.txt`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-027.txt`. The milestone fence is `.agent/milestone-files/EP-027-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-027.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-027-contextual-help-setup-coach-and-source-index.md`
- `.agent/node-contracts/EP-027.md`
- `.agent/expected-files/EP-027.txt`
- `.agent/expected-files/EP-027.discovered.txt`
- `.agent/milestone-files/EP-027-M1.txt`
- `.agent/milestone-files/EP-027-M2.txt`
- `.agent/milestone-files/EP-027-M3.txt`
- `.agent/milestone-files/EP-027-M4.txt`
- `.agent/milestone-files/EP-027-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-027/`
- `scripts/node-verifiers/EP-027.sh`
- `tests/live-fire/LF-027-help-coach-no-side-effects.sh`
- `tests/wiremudder/ep027/`
- `docs/wiremudder/help/`
- `src/wiremudder/ui/help/`
- `wirecore/crates/wire-help/`
- `schemas/wiremudder/help/`
- `tools/help-indexer/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-027.md`.
- Accepted specifications: SPEC-007, SPEC-010, SPEC-018, SPEC-022.
- Live-fire: `LF-027` `help-coach-no-side-effects`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Contextual Help, Setup Coach, and Source Index.

READ:
- `.agent/execplans/EP-027-contextual-help-setup-coach-and-source-index.md`
- `.agent/node-contracts/EP-027.md`
- `.agent/milestone-files/EP-027-M1.txt`
- `.agent/expected-files/EP-027.txt`
- `.agent/expected-files/EP-027.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-027-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0109, WM-FEAT-0111, WM-FEAT-0112, WM-FEAT-0187, WM-FEAT-0213, WM-FEAT-0214, WM-FEAT-0215, WM-FEAT-0216, WM-FEAT-0217, WM-FEAT-0218, WM-FEAT-0219.
3. Review owned requirements: WM-SPEC-007-R09, WM-SPEC-018-R04, WM-SPEC-018-R05, WM-SPEC-018-R09.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-027`
2. `sh scripts/record-evidence.sh EP-027 M1 "EP-027 M1: ok" -- sh scripts/node-verifiers/EP-027.sh M1`
3. `sh scripts/scope-audit.sh EP-027`

EXPECT:
- `EP-027 M1: ok`
- `scope audit EP-027: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-027 MILESTONE_PASS "M1 EP-027 M1: ok; evidence=.agent/state/evidence/EP-027/M1"`

FALLBACK: Ship static local help and field-level documentation links without AI or source indexing.

COMMIT: `git add -A && git commit -m "[EP-027][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Contextual Help, Setup Coach, and Source Index inside namespaced boundaries.

READ:
- `.agent/execplans/EP-027-contextual-help-setup-coach-and-source-index.md`
- `.agent/node-contracts/EP-027.md`
- `.agent/milestone-files/EP-027-M2.txt`
- `.agent/expected-files/EP-027.txt`
- `.agent/expected-files/EP-027.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-027-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-027`
2. `sh scripts/record-evidence.sh EP-027 M2 "EP-027 M2: ok" -- sh scripts/node-verifiers/EP-027.sh M2`
3. `sh scripts/scope-audit.sh EP-027`

EXPECT:
- `EP-027 M2: ok`
- `scope audit EP-027: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-027 MILESTONE_PASS "M2 EP-027 M2: ok; evidence=.agent/state/evidence/EP-027/M2"`

FALLBACK: Ship static local help and field-level documentation links without AI or source indexing.

COMMIT: `git add -A && git commit -m "[EP-027][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Contextual Help, Setup Coach, and Source Index with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-027-contextual-help-setup-coach-and-source-index.md`
- `.agent/node-contracts/EP-027.md`
- `.agent/milestone-files/EP-027-M3.txt`
- `.agent/expected-files/EP-027.txt`
- `.agent/expected-files/EP-027.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-027-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-027`
2. `sh scripts/record-evidence.sh EP-027 M3 "EP-027 M3: ok" -- sh scripts/node-verifiers/EP-027.sh M3`
3. `sh scripts/scope-audit.sh EP-027`

EXPECT:
- `EP-027 M3: ok`
- `scope audit EP-027: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-027 MILESTONE_PASS "M3 EP-027 M3: ok; evidence=.agent/state/evidence/EP-027/M3"`

FALLBACK: Ship static local help and field-level documentation links without AI or source indexing.

COMMIT: `git add -A && git commit -m "[EP-027][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Contextual Help, Setup Coach, and Source Index deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-027-contextual-help-setup-coach-and-source-index.md`
- `.agent/node-contracts/EP-027.md`
- `.agent/milestone-files/EP-027-M4.txt`
- `.agent/expected-files/EP-027.txt`
- `.agent/expected-files/EP-027.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-027-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-027`
2. `sh scripts/record-evidence.sh EP-027 M4 "EP-027 M4: ok" -- sh scripts/node-verifiers/EP-027.sh M4`
3. `sh scripts/scope-audit.sh EP-027`

EXPECT:
- `EP-027 M4: ok`
- `scope audit EP-027: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-027 MILESTONE_PASS "M4 EP-027 M4: ok; evidence=.agent/state/evidence/EP-027/M4"`

FALLBACK: Ship static local help and field-level documentation links without AI or source indexing.

COMMIT: `git add -A && git commit -m "[EP-027][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Contextual Help, Setup Coach, and Source Index, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-027-contextual-help-setup-coach-and-source-index.md`
- `.agent/node-contracts/EP-027.md`
- `.agent/milestone-files/EP-027-M5.txt`
- `.agent/expected-files/EP-027.txt`
- `.agent/expected-files/EP-027.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-027-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-027` at `tests/live-fire/LF-027-help-coach-no-side-effects.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-027`
2. `sh scripts/record-evidence.sh EP-027 M5 "EP-027 M5: ok" -- sh scripts/node-verifiers/EP-027.sh M5`
3. `sh scripts/scope-audit.sh EP-027`

EXPECT:
- `EP-027 M5: ok`
- `scope audit EP-027: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-027 MILESTONE_PASS "M5 EP-027 M5: ok; evidence=.agent/state/evidence/EP-027/M5"`

FALLBACK: Ship static local help and field-level documentation links without AI or source indexing.

COMMIT: `git add -A && git commit -m "[EP-027][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-027` and require `node verify EP-027: ok`. Then run `sh scripts/expected-files-audit.sh EP-027`, `sh scripts/scope-audit.sh EP-027`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [x] M3: Real integration and user-visible flow
- [x] M4: Forced failures, abuse cases, performance, and operations
- [ ] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

Append dated evidence-backed discoveries. Speculation is not a discovery.

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

## 15. M1 Progress

- 2026-08-28: Lease acquired (known EP-018 ellipsis preflight FAIL, documented, outside fence).
- Source evidence WM-SRC-000180..000185: accepted docs tree, COMMANDS.md command catalog, UI boundary pattern, src/CMakeLists.txt integration point, headless supervisor CLI anchor, SPEC-018-R06 coach-authority anchor.
- Discovered-path amendment for src/CMakeLists.txt (WM-SRC-000183); help-build-integration contract test.
- Contract tests: help-authority, help-boundaries, help-build-integration, help-obligations — all ok.
- Node verifier scripts/node-verifiers/EP-027.sh (M1-M5 + verify, 11 features + 4 requirements).
- `node contract check EP-027: ok`; `EP-027 M1: ok`; `scope audit EP-027: ok changed=9`.

## 16. M2 Progress

- 2026-08-28: wire-help crate (wirecore/crates/wire-help) — Help Knowledge Index (reproducible via stable_hash; 6 source kinds; stale/unavailable source reporting), field help bubbles (safe default/validation hint/privacy note/doc link), scoped sanitized Ask context (secret redaction, approved-ref filtering), help modes (local-only/remote-redacted/disabled), Setup Coach (propose-only, apply_step hard-denied, side-effect-free), source index (opt-in/local/idle/secret-aware/ignore-aware/resumable/removable), evidence-based capability onboarding (no guessing), CLI/UI help parity, app versioning. 27/27 deterministic tests.
- Help schemas schemas/wiremudder/help/ (index-entry/field-help/ask-context/coach-step/source-index-state v1).
- tools/help-indexer: real Rust CLI ingesting docs/, COMMANDS.md, schemas/wiremudder/, ADRs, sanitized source refs; reproducible output (identical runs, identical hash) — 174 entries across all 6 kinds.
- M2 unit test scripts (help-schemas, wire-help, help-indexer). `EP-027 M2: ok`; `scope audit EP-027: ok changed=25`.

## 17. M3 Progress

- 2026-08-28: Help UI boundary src/wiremudder/ui/help/help_boundary.{h,cpp} (passive Qt6 model-side pane, bubbles, coach steps propose-only, help modes, ask-context, capability probes, source-index state, no command/mutation path). Wired into src/CMakeLists.txt mudlet_SRCS + UI headers (discovered amendment WM-SRC-000183). Compiles clean vs real Qt6 with -Wall -Wextra zero warnings.
- Rust e2e example e2e_help.rs proves all 6 acceptance obligations with real output lines (accepted sources, sanitized AI context, coach no-mutation, opt-in/local/idle/removable source index, evidence-based capabilities, CLI parity).
- Integration test help-boundary-qt6 (compile proof + passive/no-settings/no-apply invariants); e2e test help-flow (6 obligation greps).
- Design docs docs/wiremudder/help/design/architecture.md (data scope, privacy, authority, audit, health, restart, fallback, rollback).
- `EP-027 M3: ok`; `scope audit EP-027: ok changed=33`.

## 18. M4 Progress

- 2026-08-28: failure_matrix (8/8 proofs), security_matrix (5/5 proofs), perf_fixture (6 measured paths).
- Real finding: help-indexer walk() compared p.extension() ("md") against ext (".md") so docs ingestion silently produced 0 entries; fixed by trimming the leading dot. Also: failure-8 exposed that the versions map lacked command-catalog, returning UnavailableSource instead of the entry — fixture now carries all kind versions. Both fixes verified by re-running.
- Perf (release, real hardware): index-add 0.66us, answer-lookup 0.35us, ask-context 1.21us, coach-propose 0.01us, source-index-scan 1.60us, cli-help 0.84us. worst 1.60us vs 5000us budget (SPEC-018-R10 non-blocking).
- Operations runbook docs/wiremudder/help/operations/runbook.md (health, readiness, disable, recovery, backup/restore, upgrade, rollback).
- `EP-027 M4: ok`; `scope audit EP-027: ok changed=41`.
