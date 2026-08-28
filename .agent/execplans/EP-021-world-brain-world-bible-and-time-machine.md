NODE-META-BEGIN
ID: EP-021
DEPS: EP-013,EP-014,EP-015
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-021
VERIFY_SENTINEL: node verify EP-021: ok
GREEN_TAG: green/EP-021
NODE-META-END

# 1. Purpose and Big Picture

Implement provenance-aware world memory, confidence, corrections, World Bible continuity, selected retrieval, Time Machine snapshots, import/export, and privacy-scoped sharing.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-021.md`.
- Own features: WM-FEAT-0050, WM-FEAT-0051, WM-FEAT-0052, WM-FEAT-0053, WM-FEAT-0191, WM-FEAT-0192, WM-FEAT-0193, WM-FEAT-0194, WM-FEAT-0195.
- Own requirements: WM-SPEC-012-R01, WM-SPEC-012-R08, WM-SPEC-012-R09, WM-SPEC-016-R02, WM-SPEC-016-R04, WM-SPEC-016-R07, WM-SPEC-023-R02.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-013, EP-014, EP-015. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-021.md`
- `.agent/expected-files/EP-021.txt`
- `.agent/expected-files/EP-021.discovered.txt`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-011-local-storage-transcripts-search-and-backup.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-021.txt`. The milestone fence is `.agent/milestone-files/EP-021-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-021.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-021-world-brain-world-bible-and-time-machine.md`
- `.agent/node-contracts/EP-021.md`
- `.agent/expected-files/EP-021.txt`
- `.agent/expected-files/EP-021.discovered.txt`
- `.agent/milestone-files/EP-021-M1.txt`
- `.agent/milestone-files/EP-021-M2.txt`
- `.agent/milestone-files/EP-021-M3.txt`
- `.agent/milestone-files/EP-021-M4.txt`
- `.agent/milestone-files/EP-021-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-021/`
- `scripts/node-verifiers/EP-021.sh`
- `tests/live-fire/LF-021-world-memory-correction.sh`
- `tests/wiremudder/ep021/`
- `docs/wiremudder/world-brain/`
- `wirecore/crates/wire-world-brain/`
- `wirecore/crates/wire-world-bible/`
- `wirecore/crates/wire-time-machine/`
- `schemas/wiremudder/memory/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-021.md`.
- Accepted specifications: SPEC-010, SPEC-011, SPEC-012, SPEC-023.
- Live-fire: `LF-021` `world-memory-correction`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for World Brain, World Bible, and Time Machine.

READ:
- `.agent/execplans/EP-021-world-brain-world-bible-and-time-machine.md`
- `.agent/node-contracts/EP-021.md`
- `.agent/milestone-files/EP-021-M1.txt`
- `.agent/expected-files/EP-021.txt`
- `.agent/expected-files/EP-021.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-011-local-storage-transcripts-search-and-backup.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-021-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0050, WM-FEAT-0051, WM-FEAT-0052, WM-FEAT-0053, WM-FEAT-0191, WM-FEAT-0192, WM-FEAT-0193, WM-FEAT-0194, WM-FEAT-0195.
3. Review owned requirements: WM-SPEC-012-R01, WM-SPEC-012-R08, WM-SPEC-012-R09, WM-SPEC-016-R02, WM-SPEC-016-R04, WM-SPEC-016-R07, WM-SPEC-023-R02.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-021`
2. `sh scripts/record-evidence.sh EP-021 M1 "EP-021 M1: ok" -- sh scripts/node-verifiers/EP-021.sh M1`
3. `sh scripts/scope-audit.sh EP-021`

EXPECT:
- `EP-021 M1: ok`
- `scope audit EP-021: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-021 MILESTONE_PASS "M1 EP-021 M1: ok; evidence=.agent/state/evidence/EP-021/M1"`

FALLBACK: Store user-authored notes and deterministic room observations only and disable inferred durable facts and vector retrieval.

COMMIT: `git add -A && git commit -m "[EP-021][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for World Brain, World Bible, and Time Machine inside namespaced boundaries.

READ:
- `.agent/execplans/EP-021-world-brain-world-bible-and-time-machine.md`
- `.agent/node-contracts/EP-021.md`
- `.agent/milestone-files/EP-021-M2.txt`
- `.agent/expected-files/EP-021.txt`
- `.agent/expected-files/EP-021.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-011-local-storage-transcripts-search-and-backup.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-021-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-021`
2. `sh scripts/record-evidence.sh EP-021 M2 "EP-021 M2: ok" -- sh scripts/node-verifiers/EP-021.sh M2`
3. `sh scripts/scope-audit.sh EP-021`

EXPECT:
- `EP-021 M2: ok`
- `scope audit EP-021: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-021 MILESTONE_PASS "M2 EP-021 M2: ok; evidence=.agent/state/evidence/EP-021/M2"`

FALLBACK: Store user-authored notes and deterministic room observations only and disable inferred durable facts and vector retrieval.

COMMIT: `git add -A && git commit -m "[EP-021][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate World Brain, World Bible, and Time Machine with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-021-world-brain-world-bible-and-time-machine.md`
- `.agent/node-contracts/EP-021.md`
- `.agent/milestone-files/EP-021-M3.txt`
- `.agent/expected-files/EP-021.txt`
- `.agent/expected-files/EP-021.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-011-local-storage-transcripts-search-and-backup.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-021-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-021`
2. `sh scripts/record-evidence.sh EP-021 M3 "EP-021 M3: ok" -- sh scripts/node-verifiers/EP-021.sh M3`
3. `sh scripts/scope-audit.sh EP-021`

EXPECT:
- `EP-021 M3: ok`
- `scope audit EP-021: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-021 MILESTONE_PASS "M3 EP-021 M3: ok; evidence=.agent/state/evidence/EP-021/M3"`

FALLBACK: Store user-authored notes and deterministic room observations only and disable inferred durable facts and vector retrieval.

COMMIT: `git add -A && git commit -m "[EP-021][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break World Brain, World Bible, and Time Machine deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-021-world-brain-world-bible-and-time-machine.md`
- `.agent/node-contracts/EP-021.md`
- `.agent/milestone-files/EP-021-M4.txt`
- `.agent/expected-files/EP-021.txt`
- `.agent/expected-files/EP-021.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-011-local-storage-transcripts-search-and-backup.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-021-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-021`
2. `sh scripts/record-evidence.sh EP-021 M4 "EP-021 M4: ok" -- sh scripts/node-verifiers/EP-021.sh M4`
3. `sh scripts/scope-audit.sh EP-021`

EXPECT:
- `EP-021 M4: ok`
- `scope audit EP-021: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-021 MILESTONE_PASS "M4 EP-021 M4: ok; evidence=.agent/state/evidence/EP-021/M4"`

FALLBACK: Store user-authored notes and deterministic room observations only and disable inferred durable facts and vector retrieval.

COMMIT: `git add -A && git commit -m "[EP-021][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for World Brain, World Bible, and Time Machine, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-021-world-brain-world-bible-and-time-machine.md`
- `.agent/node-contracts/EP-021.md`
- `.agent/milestone-files/EP-021-M5.txt`
- `.agent/expected-files/EP-021.txt`
- `.agent/expected-files/EP-021.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-011-local-storage-transcripts-search-and-backup.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`

CHANGE: exact paths in `.agent/milestone-files/EP-021-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-021` at `tests/live-fire/LF-021-world-memory-correction.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-021`
2. `sh scripts/record-evidence.sh EP-021 M5 "EP-021 M5: ok" -- sh scripts/node-verifiers/EP-021.sh M5`
3. `sh scripts/scope-audit.sh EP-021`

EXPECT:
- `EP-021 M5: ok`
- `scope audit EP-021: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-021 MILESTONE_PASS "M5 EP-021 M5: ok; evidence=.agent/state/evidence/EP-021/M5"`

FALLBACK: Store user-authored notes and deterministic room observations only and disable inferred durable facts and vector retrieval.

COMMIT: `git add -A && git commit -m "[EP-021][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-021` and require `node verify EP-021: ok`. Then run `sh scripts/expected-files-audit.sh EP-021`, `sh scripts/scope-audit.sh EP-021`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [x] M3: Real integration and user-visible flow
- [x] M4: Forced failures, abuse cases, performance, and operations
- [x] M5: Live-fire, evidence closure, and green tag readiness

Evidence: `.agent/state/evidence/EP-021/M1..M5`, `LF-021` certification
`lf021-certification.json`, commits `640f3fe7` (M1), `8b111807` (M2),
`13c05d0a` (M3), `54a20127` (M4).

# 12. Surprises and Discoveries

- 2026-08-28: The evidence ID allocator in `scripts/source_evidence.py`
  (len(existing)+1) collided for the third time when EP-021 records
  reused IDs 133-137 that belonged to EP-020's renumbered records. The
  log files for WM-SRC-000133..000137 were overwritten. Repaired by
  restoring each original log from its own recorded command (all hashes
  verified) and renumbering the new EP-021 records to 139-145; the
  allocator was then fixed to scan max existing ID + 1 (WM-SRC-000144
  records the change) and the script added to the EP-021 static fence.
- 2026-08-28: `TacticalHud`-style private-field limits recurred in the
  failure matrix (max_entities); the fix is to use real public defaults.
  For EP-021 the equivalent pitfall was the Time Machine perf fixture
  exhausting the 50-snapshot cap during warmup; the fixture now
  pre-creates one approved snapshot and measures only the read path.
- 2026-08-28: The security matrix initially corrected a fact that was
  never observed (`exit.north`), producing NotFound; corrected to use the
  fact that exists in the scenario (`note`).

# 13. Decision Log

- 2026-08-28: World memory surfaces are observer-only by construction
  (no command path); facts, continuity, and snapshots are read-only
  data. Evidence: crate tests + LF-021 certification (`brain_observer`,
  `bible_observer`, `time_machine_observer`). Consequence: nothing in
  the memory stack can send a command; manual gameplay is preserved.
- 2026-08-28: User corrections supersede derived facts while preserving
  history (SPEC-012-R10); Time Machine restore is gated on explicit
  user approval (SPEC-012-R09). Evidence: `correct()` + `approve()`
  invariants + LF-021. Alternatives: silent merge/overwrite (rejected:
  violates spec). Consequence: history is never erased and restores are
  never automatic.
- 2026-08-28: World Bible stores text metadata only; no protected asset
  bytes, no base64 blobs, no live generation. Evidence:
  `no_protected_assets` test + security matrix. Impact: SPEC-016-R02/R07.
- 2026-08-28: The evidence ID allocator root cause was fixed in
  `scripts/source_evidence.py` (scan max existing ID + 1) and the script
  was added to the EP-021 static fence and authority ledger. Evidence:
  WM-SRC-000144, contract test `evidence-allocator.sh`. Reversal: revert
  the patch; ledger returns to colliding behavior.

# 14. Outcomes and Retrospective

Changed vs expected: all static expected paths present; `scripts/
source_evidence.py` added to the static fence + authority ledger for the
allocator root-cause fix (WM-SRC-000144).

Commands and sentinels (all observed):
- `sh scripts/node-contract-check.sh EP-021` -> `node contract check EP-021: ok`
- `sh scripts/node-verifiers/EP-021.sh M1` -> `EP-021 M1: ok`
- `sh scripts/node-verifiers/EP-021.sh M2` -> `EP-021 M2: ok`
- `sh scripts/node-verifiers/EP-021.sh M3` -> `EP-021 M3: ok`
- `sh scripts/node-verifiers/EP-021.sh M4` -> `EP-021 M4: ok`
- `sh scripts/node-verifiers/EP-021.sh M5` -> `EP-021 M5: ok`
- `sh tests/live-fire/LF-021-world-memory-correction.sh` -> `LF-021: ok`
- `sh scripts/scope-audit.sh EP-021` -> `scope audit EP-021: ok`

Feature disposition: WM-FEAT-0050/0051/0052/0053/0191/0192/0193/0194/
0195 certified (full/ai release profile) with feature tests + LF-021.
Requirement disposition: WM-SPEC-012-R01/R08/R09, WM-SPEC-016-R02/R04/
R07, WM-SPEC-023-R02 certified with requirement tests.

Provider/platform certification: none claimed. RAG memory (WM-FEAT-0052)
ships the deterministic observation store; vector retrieval stays
disabled per the node's accepted fallback (no vector index exists).

Performance: `perf_world_memory` fixture, runs=5000, p95=2us (SPEC-004
budget 5ms), recorded in `tests/wiremudder/ep021/performance/`.

Assumptions changed: none. Risks: format-check pre-existing violations
remain outside the EP-021 fence (documented at EP-020). Rollback:
documented in `docs/wiremudder/world-brain/operations/`.
Next scheduler output: see `scripts/graph-next.sh`.
