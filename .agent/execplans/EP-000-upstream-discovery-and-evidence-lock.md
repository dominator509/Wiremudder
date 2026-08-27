NODE-META-BEGIN
ID: EP-000
DEPS: -
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-000
VERIFY_SENTINEL: node verify EP-000: ok
GREEN_TAG: green/EP-000
NODE-META-END

# 1. Purpose and Big Picture

Inspect the actual Mudlet-derived repository, verify the pinned upstream commit and release evidence, inventory source, build, tests, dependencies, licenses, packages, agent instructions, and platform commands, and create a machine-readable source-evidence baseline before any product edit.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-000.md`.
- Own features: WM-FEAT-0147, WM-FEAT-0150.
- Own requirements: WM-SPEC-000-R02, WM-SPEC-000-R04, WM-SPEC-000-R05, WM-SPEC-000-R06, WM-SPEC-000-R07, WM-SPEC-000-R08, WM-SPEC-001-R01, WM-SPEC-001-R02, WM-SPEC-001-R05, WM-SPEC-001-R06, WM-SPEC-001-R09, WM-SPEC-001-R10.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on no prior node. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-000.md`
- `.agent/expected-files/EP-000.txt`
- `.agent/expected-files/EP-000.discovered.txt`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-000.txt`. The milestone fence is `.agent/milestone-files/EP-000-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-000.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-000-upstream-discovery-and-evidence-lock.md`
- `.agent/node-contracts/EP-000.md`
- `.agent/expected-files/EP-000.txt`
- `.agent/expected-files/EP-000.discovered.txt`
- `.agent/milestone-files/EP-000-M1.txt`
- `.agent/milestone-files/EP-000-M2.txt`
- `.agent/milestone-files/EP-000-M3.txt`
- `.agent/milestone-files/EP-000-M4.txt`
- `.agent/milestone-files/EP-000-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-000/`
- `scripts/node-verifiers/EP-000.sh`
- `tests/live-fire/LF-000-upstream-baseline-discovery.sh`
- `tests/wiremudder/ep000/`
- `docs/wiremudder/discovery/`
- `UPSTREAM.lock.yaml`
- `docs/upstream/`
- `.agent/state/upstream-tree.tsv`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-000.md`.
- Accepted specifications: SPEC-000, SPEC-001, SPEC-005, SPEC-027.
- Live-fire: `LF-000` `upstream-baseline-discovery`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Upstream Discovery and Evidence Lock.

READ:
- `.agent/execplans/EP-000-upstream-discovery-and-evidence-lock.md`
- `.agent/node-contracts/EP-000.md`
- `.agent/milestone-files/EP-000-M1.txt`
- `.agent/expected-files/EP-000.txt`
- `.agent/expected-files/EP-000.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-000-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0147, WM-FEAT-0150.
3. Review owned requirements: WM-SPEC-000-R02, WM-SPEC-000-R04, WM-SPEC-000-R05, WM-SPEC-000-R06, WM-SPEC-000-R07, WM-SPEC-000-R08, WM-SPEC-001-R01, WM-SPEC-001-R02, WM-SPEC-001-R05, WM-SPEC-001-R06, WM-SPEC-001-R09, WM-SPEC-001-R10.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-000`
2. `sh scripts/record-evidence.sh EP-000 M1 "EP-000 M1: ok" -- sh scripts/node-verifiers/EP-000.sh M1`
3. `sh scripts/scope-audit.sh EP-000`

EXPECT:
- `EP-000 M1: ok`
- `scope audit EP-000: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-000 MILESTONE_PASS "M1 EP-000 M1: ok; evidence=.agent/state/evidence/EP-000/M1"`

FALLBACK: Use the locked stable Mudlet release tag as a temporary read-only comparison baseline while leaving implementation blocked until the development commit can be verified.

COMMIT: `git add -A && git commit -m "[EP-000][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Upstream Discovery and Evidence Lock inside namespaced boundaries.

READ:
- `.agent/execplans/EP-000-upstream-discovery-and-evidence-lock.md`
- `.agent/node-contracts/EP-000.md`
- `.agent/milestone-files/EP-000-M2.txt`
- `.agent/expected-files/EP-000.txt`
- `.agent/expected-files/EP-000.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-000-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-000`
2. `sh scripts/record-evidence.sh EP-000 M2 "EP-000 M2: ok" -- sh scripts/node-verifiers/EP-000.sh M2`
3. `sh scripts/scope-audit.sh EP-000`

EXPECT:
- `EP-000 M2: ok`
- `scope audit EP-000: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-000 MILESTONE_PASS "M2 EP-000 M2: ok; evidence=.agent/state/evidence/EP-000/M2"`

FALLBACK: Use the locked stable Mudlet release tag as a temporary read-only comparison baseline while leaving implementation blocked until the development commit can be verified.

COMMIT: `git add -A && git commit -m "[EP-000][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Upstream Discovery and Evidence Lock with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-000-upstream-discovery-and-evidence-lock.md`
- `.agent/node-contracts/EP-000.md`
- `.agent/milestone-files/EP-000-M3.txt`
- `.agent/expected-files/EP-000.txt`
- `.agent/expected-files/EP-000.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-000-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-000`
2. `sh scripts/record-evidence.sh EP-000 M3 "EP-000 M3: ok" -- sh scripts/node-verifiers/EP-000.sh M3`
3. `sh scripts/scope-audit.sh EP-000`

EXPECT:
- `EP-000 M3: ok`
- `scope audit EP-000: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-000 MILESTONE_PASS "M3 EP-000 M3: ok; evidence=.agent/state/evidence/EP-000/M3"`

FALLBACK: Use the locked stable Mudlet release tag as a temporary read-only comparison baseline while leaving implementation blocked until the development commit can be verified.

COMMIT: `git add -A && git commit -m "[EP-000][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Upstream Discovery and Evidence Lock deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-000-upstream-discovery-and-evidence-lock.md`
- `.agent/node-contracts/EP-000.md`
- `.agent/milestone-files/EP-000-M4.txt`
- `.agent/expected-files/EP-000.txt`
- `.agent/expected-files/EP-000.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-000-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-000`
2. `sh scripts/record-evidence.sh EP-000 M4 "EP-000 M4: ok" -- sh scripts/node-verifiers/EP-000.sh M4`
3. `sh scripts/scope-audit.sh EP-000`

EXPECT:
- `EP-000 M4: ok`
- `scope audit EP-000: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-000 MILESTONE_PASS "M4 EP-000 M4: ok; evidence=.agent/state/evidence/EP-000/M4"`

FALLBACK: Use the locked stable Mudlet release tag as a temporary read-only comparison baseline while leaving implementation blocked until the development commit can be verified.

COMMIT: `git add -A && git commit -m "[EP-000][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Upstream Discovery and Evidence Lock, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-000-upstream-discovery-and-evidence-lock.md`
- `.agent/node-contracts/EP-000.md`
- `.agent/milestone-files/EP-000-M5.txt`
- `.agent/expected-files/EP-000.txt`
- `.agent/expected-files/EP-000.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-000-product-scope-and-release-profiles.md`
- `.agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-000-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-000` at `tests/live-fire/LF-000-upstream-baseline-discovery.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-000`
2. `sh scripts/record-evidence.sh EP-000 M5 "EP-000 M5: ok" -- sh scripts/node-verifiers/EP-000.sh M5`
3. `sh scripts/scope-audit.sh EP-000`

EXPECT:
- `EP-000 M5: ok`
- `scope audit EP-000: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-000 MILESTONE_PASS "M5 EP-000 M5: ok; evidence=.agent/state/evidence/EP-000/M5"`

FALLBACK: Use the locked stable Mudlet release tag as a temporary read-only comparison baseline while leaving implementation blocked until the development commit can be verified.

COMMIT: `git add -A && git commit -m "[EP-000][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-000` and require `node verify EP-000: ok`. Then run `sh scripts/expected-files-audit.sh EP-000`, `sh scripts/scope-audit.sh EP-000`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

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

- 2026-08-27: Bootstrap uses a direct clone of Mudlet at pinned commit 77086c295f4adf59197e586e689d19bdde8e1008 with `upstream` remote preserved and no origin remote yet (origin URL is operator-provided per HOW_TO_USE). Evidence: git rev-parse HEAD, remote -v. Alternative: bootstrap-fork.sh requires WIREMUDDER_ORIGIN_URL; deferred because operator must supply the repository URL. Consequence: no push capability until origin is configured; EP-002 fork governance will require it. Reversal: add origin remote when URL is provided. Affects: WM-SPEC-001-R01. Security: no credentials involved. Privacy: n/a. License: GPL-2.0-or-later preserved. Compatibility: upstream history intact. Performance: n/a. Upstream impact: none.
- 2026-08-27: Overlay collision handling: upstream AGENTS.md/CLAUDE.md/.github/copilot-instructions.md are symlinks to docs/ai-instructions.md; the overlay replaces the symlinks with Graphlock control adapters and preserves docs/ai-instructions.md byte-for-byte. Evidence: sha256 sha256 a6802bfeedc78802e085e70b443bbe4641f8d0fb662d69c5ade8abe8b39d8e7a for docs/ai-instructions.md, authority check 545 files ok. Alternative: writing through symlinks would clobber upstream instructions; rejected. Consequence: control plane is real files, upstream instructions preserved at docs/ai-instructions.md. Reversal: git checkout of pinned baseline. Affects: WM-SPEC-001-R01, WM-SPEC-001-R03. Security: n/a. License: preserved. Compatibility: build-mudlet skill and .agents/skills untouched. Performance: n/a. Upstream impact: none.
- 2026-08-27: Selected CMake preset linux-debug-nosan for baseline discovery and build work; avoids AddressSanitizer overhead in the discovery node. Evidence: cmake --list-presets output; preflight: ok. Alternative: linux-debug (ASan) is slower; linux-lowspec drops 3D mapper. Consequence: builds land in build-linux-debug-nosan/. Reversal: change WIREMUDDER_CMAKE_PRESET in .env. Affects: toolchain evidence. Security: n/a. Performance: faster baseline runs. Upstream impact: none.
- 2026-08-27: M1 source evidence recorded for 18 inherited paths/symbols (WM-SRC-000001 through WM-SRC-000018) covering AI instructions, build skill, presets, license, submodules, core classes, Lua interpreter, lock file, and 3rdparty before any product edit. Evidence: .agent/state/source-evidence.jsonl. Alternative: none - required by anti-hallucination rule. Consequence: every inherited claim in EP-000 is now evidence-backed. Reversal: remove records (not recommended). Affects: WM-FEAT-0147, WM-FEAT-0150. Security: n/a. License: verified. Compatibility: baseline locked. Performance: n/a. Upstream impact: none.
- 2026-08-27: M2 generated `.agent/state/upstream-tree.tsv` (1393 tracked paths at pinned commit, schema v1: path/type/mode/size/blob_sha) via `tests/wiremudder/ep000/unit/gen_upstream_tree.py` and locked the canonical Linux commands (configure/build/unit) in `.agent/state/COMMANDS.lock.tsv` backed by evidence WM-SRC-000019 whose output contains each exact command. Evidence: command-lock-check rows=3 ok; unit tests 001-004 pass. Alternative: none - the graph requires machine-readable inventory and command lock before builds. Consequence: builds must run through the locked wrappers; upstream-tree.tsv is the deterministic baseline for later drift checks. Reversal: regenerate with the same generator; rollback via git revert. Affects: WM-FEAT-0147, WM-SPEC-001-R02, WM-SPEC-001-R08. Security: no secrets. License: verified GPL. Compatibility: read-only inventory, no inherited edits. Performance: 1393 blobs hashed once. Upstream impact: none.
- 2026-08-27: M3 added integration tests (lock-state, tree-inventory, submodule-inventory, evidence-chain) and E2E boot-gate-chain covering the full gate path. Evidence: M3 verifier sentinel EP-000 M3: ok; 1393-path inventory matches git ls-tree exactly; 5 gitlink submodules match .gitmodules. Alternative: a full build would overreach EP-000 scope (builds belong to later nodes); the E2E chain proves gates pass without a build. Consequence: boot chain is reproducible and gate-checked; submodules remain uninitialized gitlinks pending the build node. Reversal: git revert of the M3 commit. Affects: WM-FEAT-0147, WM-FEAT-0150, WM-SPEC-001-R02. Security: no secrets. License: n/a. Compatibility: no inherited edits. Performance: gate chain runs in seconds. Upstream impact: none.
- 2026-08-27: M4 added failure proofs (evidence non-zero exit, state-change rejection, malformed discovered path, lease-dispatch bound), security proofs (path traversal, dangerous command lock, evidence output secret scan), and performance budgets (gate chain under 60s, inventory under 60s). Evidence: M4 verifier sentinel; gate chain measured 6.4s; inventory measured 4.1s for 1393 paths. Alternative: mocking failures was rejected by the reality gate; real controlled failures used. Consequence: evidence and command lock fail closed on abuse; budgets recorded for later drift. Reversal: git revert of the M4 commit. Affects: WM-FEAT-0147, WM-FEAT-0150, WM-SPEC-001-R10. Security: no secrets; evidence outputs scanned for credential patterns. License: n/a. Compatibility: no inherited edits. Performance: budgets recorded. Upstream impact: none.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.
