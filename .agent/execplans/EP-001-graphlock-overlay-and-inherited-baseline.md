NODE-META-BEGIN
ID: EP-001
DEPS: EP-000
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-001
VERIFY_SENTINEL: node verify EP-001: ok
GREEN_TAG: green/EP-001
NODE-META-END

# 1. Purpose and Big Picture

Install the Graphlock control plane into the Mudlet-derived repository, preserve upstream instructions, build the inherited client without functional WireMudder changes, and prove the reference baseline user flow.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-001.md`.
- Own features: WM-FEAT-0146, WM-FEAT-0154.
- Own requirements: WM-SPEC-000-R03, WM-SPEC-002-R01, WM-SPEC-002-R02, WM-SPEC-002-R05, WM-SPEC-002-R08, WM-SPEC-002-R10, WM-SPEC-005-R01, WM-SPEC-005-R03, WM-SPEC-005-R04, WM-SPEC-005-R05, WM-SPEC-005-R09.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-000. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-001.md`
- `.agent/expected-files/EP-001.txt`
- `.agent/expected-files/EP-001.discovered.txt`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-002-hybrid-runtime-architecture.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-001.txt`. The milestone fence is `.agent/milestone-files/EP-001-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-001.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-001-graphlock-overlay-and-inherited-baseline.md`
- `.agent/node-contracts/EP-001.md`
- `.agent/expected-files/EP-001.txt`
- `.agent/expected-files/EP-001.discovered.txt`
- `.agent/milestone-files/EP-001-M1.txt`
- `.agent/milestone-files/EP-001-M2.txt`
- `.agent/milestone-files/EP-001-M3.txt`
- `.agent/milestone-files/EP-001-M4.txt`
- `.agent/milestone-files/EP-001-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-001/`
- `scripts/node-verifiers/EP-001.sh`
- `tests/live-fire/LF-001-unchanged-inherited-baseline.sh`
- `tests/wiremudder/ep001/`
- `docs/wiremudder/baseline/`
- `tests/wiremudder/baseline/`
- `.agent/state/baseline/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-001.md`.
- Accepted specifications: SPEC-000, SPEC-001, SPEC-002, SPEC-005.
- Live-fire: `LF-001` `unchanged-inherited-baseline`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Graphlock Overlay and Inherited Baseline.

READ:
- `.agent/execplans/EP-001-graphlock-overlay-and-inherited-baseline.md`
- `.agent/node-contracts/EP-001.md`
- `.agent/milestone-files/EP-001-M1.txt`
- `.agent/expected-files/EP-001.txt`
- `.agent/expected-files/EP-001.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-002-hybrid-runtime-architecture.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`

CHANGE: exact paths in `.agent/milestone-files/EP-001-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0146, WM-FEAT-0154.
3. Review owned requirements: WM-SPEC-000-R03, WM-SPEC-002-R01, WM-SPEC-002-R02, WM-SPEC-002-R05, WM-SPEC-002-R08, WM-SPEC-002-R10, WM-SPEC-005-R01, WM-SPEC-005-R03, WM-SPEC-005-R04, WM-SPEC-005-R05, WM-SPEC-005-R09.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-001`
2. `sh scripts/record-evidence.sh EP-001 M1 "EP-001 M1: ok" -- sh scripts/node-verifiers/EP-001.sh M1`
3. `sh scripts/scope-audit.sh EP-001`

EXPECT:
- `EP-001 M1: ok`
- `scope audit EP-001: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-001 MILESTONE_PASS "M1 EP-001 M1: ok; evidence=.agent/state/evidence/EP-001/M1"`

FALLBACK: Keep an unmodified upstream worktree as the executable baseline and apply the Graphlock overlay only to a separate WireMudder branch.

COMMIT: `git add -A && git commit -m "[EP-001][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Graphlock Overlay and Inherited Baseline inside namespaced boundaries.

READ:
- `.agent/execplans/EP-001-graphlock-overlay-and-inherited-baseline.md`
- `.agent/node-contracts/EP-001.md`
- `.agent/milestone-files/EP-001-M2.txt`
- `.agent/expected-files/EP-001.txt`
- `.agent/expected-files/EP-001.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-002-hybrid-runtime-architecture.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`

CHANGE: exact paths in `.agent/milestone-files/EP-001-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-001`
2. `sh scripts/record-evidence.sh EP-001 M2 "EP-001 M2: ok" -- sh scripts/node-verifiers/EP-001.sh M2`
3. `sh scripts/scope-audit.sh EP-001`

EXPECT:
- `EP-001 M2: ok`
- `scope audit EP-001: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-001 MILESTONE_PASS "M2 EP-001 M2: ok; evidence=.agent/state/evidence/EP-001/M2"`

FALLBACK: Keep an unmodified upstream worktree as the executable baseline and apply the Graphlock overlay only to a separate WireMudder branch.

COMMIT: `git add -A && git commit -m "[EP-001][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Graphlock Overlay and Inherited Baseline with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-001-graphlock-overlay-and-inherited-baseline.md`
- `.agent/node-contracts/EP-001.md`
- `.agent/milestone-files/EP-001-M3.txt`
- `.agent/expected-files/EP-001.txt`
- `.agent/expected-files/EP-001.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-002-hybrid-runtime-architecture.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`

CHANGE: exact paths in `.agent/milestone-files/EP-001-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-001`
2. `sh scripts/record-evidence.sh EP-001 M3 "EP-001 M3: ok" -- sh scripts/node-verifiers/EP-001.sh M3`
3. `sh scripts/scope-audit.sh EP-001`

EXPECT:
- `EP-001 M3: ok`
- `scope audit EP-001: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-001 MILESTONE_PASS "M3 EP-001 M3: ok; evidence=.agent/state/evidence/EP-001/M3"`

FALLBACK: Keep an unmodified upstream worktree as the executable baseline and apply the Graphlock overlay only to a separate WireMudder branch.

COMMIT: `git add -A && git commit -m "[EP-001][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Graphlock Overlay and Inherited Baseline deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-001-graphlock-overlay-and-inherited-baseline.md`
- `.agent/node-contracts/EP-001.md`
- `.agent/milestone-files/EP-001-M4.txt`
- `.agent/expected-files/EP-001.txt`
- `.agent/expected-files/EP-001.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-002-hybrid-runtime-architecture.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`

CHANGE: exact paths in `.agent/milestone-files/EP-001-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-001`
2. `sh scripts/record-evidence.sh EP-001 M4 "EP-001 M4: ok" -- sh scripts/node-verifiers/EP-001.sh M4`
3. `sh scripts/scope-audit.sh EP-001`

EXPECT:
- `EP-001 M4: ok`
- `scope audit EP-001: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-001 MILESTONE_PASS "M4 EP-001 M4: ok; evidence=.agent/state/evidence/EP-001/M4"`

FALLBACK: Keep an unmodified upstream worktree as the executable baseline and apply the Graphlock overlay only to a separate WireMudder branch.

COMMIT: `git add -A && git commit -m "[EP-001][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Graphlock Overlay and Inherited Baseline, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-001-graphlock-overlay-and-inherited-baseline.md`
- `.agent/node-contracts/EP-001.md`
- `.agent/milestone-files/EP-001-M5.txt`
- `.agent/expected-files/EP-001.txt`
- `.agent/expected-files/EP-001.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-002-hybrid-runtime-architecture.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`

CHANGE: exact paths in `.agent/milestone-files/EP-001-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-001` at `tests/live-fire/LF-001-unchanged-inherited-baseline.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-001`
2. `sh scripts/record-evidence.sh EP-001 M5 "EP-001 M5: ok" -- sh scripts/node-verifiers/EP-001.sh M5`
3. `sh scripts/scope-audit.sh EP-001`

EXPECT:
- `EP-001 M5: ok`
- `scope audit EP-001: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-001 MILESTONE_PASS "M5 EP-001 M5: ok; evidence=.agent/state/evidence/EP-001/M5"`

FALLBACK: Keep an unmodified upstream worktree as the executable baseline and apply the Graphlock overlay only to a separate WireMudder branch.

COMMIT: `git add -A && git commit -m "[EP-001][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-001` and require `node verify EP-001: ok`. Then run `sh scripts/expected-files-audit.sh EP-001`, `sh scripts/scope-audit.sh EP-001`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

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

- 2026-08-27: EP-001 M1 recorded source evidence for the Graphlock overlay and inherited baseline: AGENTS.md/CLAUDE.md prime blocks (WM-SRC-000021, 000022), preserved ai-instructions (000023), CMake Qt6/Lua requirements (000024), main entry (000025), Host save/read profile (000026), Lua startEmbedding (000027), trigger match (000028), mapper (000029), ctelnet connect (000030). Evidence: source-evidence.jsonl 30 records. Alternative: none - anti-hallucination rule requires path-level evidence before inherited claims. Consequence: every EP-001 inherited claim is evidence-backed. Reversal: remove records. Affects: WM-FEAT-0146, WM-FEAT-0154, WM-SPEC-005-R01. Security: n/a. License: GPL preserved. Compatibility: no inherited edits yet. Performance: n/a. Upstream impact: none.
- 2026-08-27: EP-001 node verifier gates M3 on an actual configured+buildable inherited client (build-$preset/CMakeCache.txt and build-$preset/src/mudlet binary) plus integration/e2e tests; M5 gates on LF-001 live-fire. Alternative: a verifier that only checks scripts would weaken the reality gate; rejected. Consequence: EP-001 cannot close until the inherited client actually builds. Reversal: change verifier only through an accepted contract change. Affects: WM-SPEC-005-R01. Security: n/a. License: n/a. Compatibility: baseline build proven. Performance: build time bounded by wrapper. Upstream impact: none.
- 2026-08-27: EP-001 M2 recorded the toolchain lock (cmake 3.28.3, ninja 1.11.1, g++ 13.3.0, lua 5.1.5, qt6 6.8.2, python 3.12.3, rust 1.96.0) at .agent/state/baseline/toolchain.lock.tsv and added baseline/unit tests proving inherited source untouched (hash-verified against pinned commit) and inventory stability (1393 paths). Evidence: M2 verifier sentinel; baseline tests 001-002; unit tests 001-003. Alternative: none - ENVIRONMENT.md requires exact observed versions. Consequence: build prerequisites are pinned and reproducible. Reversal: git revert of M2 commit. Affects: WM-FEAT-0146, WM-SPEC-002-R01. Security: n/a. License: n/a. Compatibility: inherited files byte-identical to upstream. Performance: n/a. Upstream impact: none.
- 2026-08-27: EP-001 M3 built the inherited client. System Qt 6.4.2 was rejected by find_package(Qt6 6.8.2); installed Qt 6.8.2 via aqtinstall at /opt/qt/6.8.2/gcc_64 plus qt5compat and qtmultimedia modules; added boost, assimp, hunspell, pugixml, qtkeychain-qt6-dev, and xcb runtime libs. Configure: cmake --preset linux-debug-nosan -DCMAKE_PREFIX_PATH=/opt/qt/6.8.2/gcc_64 (ok). Build: 976/976 targets, client binary build-linux-debug-nosan/src/mudlet (247MB). E2E launch: xvfb + QT_QPA_PLATFORM=offscreen stays alive (upstream CI smoke pattern). Evidence: M3 verifier sentinel; integration 001-003; e2e 001. Alternative: downgrade Qt requirement was rejected (would weaken inherited contract); system Qt was insufficient. Consequence: baseline client builds and runs; build nodes reuse this toolchain. Reversal: git revert of M3 commit; rebuild from configure. Affects: WM-FEAT-0146, WM-FEAT-0154, WM-SPEC-000-R03, WM-SPEC-005-R01. Security: configure cache scanned for secrets. License: Qt GPL/LGPL from official aqt archives. Compatibility: inherited source byte-identical; no functional changes. Performance: full build ~10min; incremental bounded. Upstream impact: none.
- 2026-08-27: EP-001 M4 added failure proofs (configure dependency-missing from fresh dir, malformed input fails closed, generator-switch rejection in temp dir), security proofs (configure cache secret scan, no build artifact leak), and performance budgets (warm incremental 611-679ms, configure ~3s). Evidence: M4 verifier sentinel. Alternative: mocks rejected by reality gate; real controlled failures used. Consequence: build fails closed on missing deps and malformed input; build tree stays clean. Reversal: git revert of M4 commit. Affects: WM-FEAT-0146, WM-FEAT-0154, WM-SPEC-005-R01. Security: cache scanned for credentials. License: n/a. Compatibility: no inherited edits. Performance: budgets recorded (15s incremental cap). Upstream impact: none.
- 2026-08-27: Origin repository created at github.com/dominator509/WireMudder (private), remote origin set, branch wire/development pushed; .gitignore verified to exclude /build*, .env, target/, node_modules/, and local state before push. Evidence: git remote -v; ls-remote origin f2066deaf. Alternative: public repo rejected (brownfield fork of GPL project; keep private until branding decision). Consequence: fork is backed up remotely; EP-002 fork governance now has a real origin. Reversal: gh repo delete. Affects: WM-SPEC-001-R01. Security: no secrets pushed; .env ignored. License: GPL preserved. Compatibility: n/a. Performance: n/a. Upstream impact: none.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.
