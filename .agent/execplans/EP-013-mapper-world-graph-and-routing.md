NODE-META-BEGIN
ID: EP-013
DEPS: EP-009
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-013
VERIFY_SENTINEL: node verify EP-013: ok
GREEN_TAG: green/EP-013
NODE-META-END

# 1. Purpose and Big Picture

Preserve advanced mapper behavior, add typed world-graph events, confidence and corrections, benchmark routing, and prepare World Brain integration without replacing the inherited map.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-013.md`.
- Own features: WM-FEAT-0165, WM-FEAT-0166, WM-FEAT-0167, WM-FEAT-0168.
- Own requirements: WM-SPEC-005-R07, WM-SPEC-012-R02, WM-SPEC-012-R03, WM-SPEC-012-R04, WM-SPEC-012-R05, WM-SPEC-012-R10.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-009. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-013.md`
- `.agent/expected-files/EP-013.txt`
- `.agent/expected-files/EP-013.discovered.txt`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-013.txt`. The milestone fence is `.agent/milestone-files/EP-013-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-013.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-013-mapper-world-graph-and-routing.md`
- `.agent/node-contracts/EP-013.md`
- `.agent/expected-files/EP-013.txt`
- `.agent/expected-files/EP-013.discovered.txt`
- `.agent/milestone-files/EP-013-M1.txt`
- `.agent/milestone-files/EP-013-M2.txt`
- `.agent/milestone-files/EP-013-M3.txt`
- `.agent/milestone-files/EP-013-M4.txt`
- `.agent/milestone-files/EP-013-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-013/`
- `scripts/node-verifiers/EP-013.sh`
- `tests/live-fire/LF-013-mapper-route-roundtrip.sh`
- `tests/wiremudder/ep013/`
- `docs/wiremudder/mapper/`
- `src/wiremudder/mapper/`
- `wirecore/crates/wire-world-graph/`
- `compatibility/maps/`
- `schemas/wiremudder/world/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-013.md`.
- Accepted specifications: SPEC-005, SPEC-012, SPEC-021, SPEC-027.
- Live-fire: `LF-013` `mapper-route-roundtrip`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Mapper, World Graph, and Routing.

READ:
- `.agent/execplans/EP-013-mapper-world-graph-and-routing.md`
- `.agent/node-contracts/EP-013.md`
- `.agent/milestone-files/EP-013-M1.txt`
- `.agent/expected-files/EP-013.txt`
- `.agent/expected-files/EP-013.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-013-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0165, WM-FEAT-0166, WM-FEAT-0167, WM-FEAT-0168.
3. Review owned requirements: WM-SPEC-005-R07, WM-SPEC-012-R02, WM-SPEC-012-R03, WM-SPEC-012-R04, WM-SPEC-012-R05, WM-SPEC-012-R10.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-013`
2. `sh scripts/record-evidence.sh EP-013 M1 "EP-013 M1: ok" -- sh scripts/node-verifiers/EP-013.sh M1`
3. `sh scripts/scope-audit.sh EP-013`

EXPECT:
- `EP-013 M1: ok`
- `scope audit EP-013: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-013 MILESTONE_PASS "M1 EP-013 M1: ok; evidence=.agent/state/evidence/EP-013/M1"`

FALLBACK: Use the inherited mapper as canonical and publish read-only room and route snapshots until write-back compatibility is proven.

COMMIT: `git add -A && git commit -m "[EP-013][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Mapper, World Graph, and Routing inside namespaced boundaries.

READ:
- `.agent/execplans/EP-013-mapper-world-graph-and-routing.md`
- `.agent/node-contracts/EP-013.md`
- `.agent/milestone-files/EP-013-M2.txt`
- `.agent/expected-files/EP-013.txt`
- `.agent/expected-files/EP-013.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-013-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-013`
2. `sh scripts/record-evidence.sh EP-013 M2 "EP-013 M2: ok" -- sh scripts/node-verifiers/EP-013.sh M2`
3. `sh scripts/scope-audit.sh EP-013`

EXPECT:
- `EP-013 M2: ok`
- `scope audit EP-013: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-013 MILESTONE_PASS "M2 EP-013 M2: ok; evidence=.agent/state/evidence/EP-013/M2"`

FALLBACK: Use the inherited mapper as canonical and publish read-only room and route snapshots until write-back compatibility is proven.

COMMIT: `git add -A && git commit -m "[EP-013][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Mapper, World Graph, and Routing with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-013-mapper-world-graph-and-routing.md`
- `.agent/node-contracts/EP-013.md`
- `.agent/milestone-files/EP-013-M3.txt`
- `.agent/expected-files/EP-013.txt`
- `.agent/expected-files/EP-013.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-013-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-013`
2. `sh scripts/record-evidence.sh EP-013 M3 "EP-013 M3: ok" -- sh scripts/node-verifiers/EP-013.sh M3`
3. `sh scripts/scope-audit.sh EP-013`

EXPECT:
- `EP-013 M3: ok`
- `scope audit EP-013: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-013 MILESTONE_PASS "M3 EP-013 M3: ok; evidence=.agent/state/evidence/EP-013/M3"`

FALLBACK: Use the inherited mapper as canonical and publish read-only room and route snapshots until write-back compatibility is proven.

COMMIT: `git add -A && git commit -m "[EP-013][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Mapper, World Graph, and Routing deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-013-mapper-world-graph-and-routing.md`
- `.agent/node-contracts/EP-013.md`
- `.agent/milestone-files/EP-013-M4.txt`
- `.agent/expected-files/EP-013.txt`
- `.agent/expected-files/EP-013.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-013-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-013`
2. `sh scripts/record-evidence.sh EP-013 M4 "EP-013 M4: ok" -- sh scripts/node-verifiers/EP-013.sh M4`
3. `sh scripts/scope-audit.sh EP-013`

EXPECT:
- `EP-013 M4: ok`
- `scope audit EP-013: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-013 MILESTONE_PASS "M4 EP-013 M4: ok; evidence=.agent/state/evidence/EP-013/M4"`

FALLBACK: Use the inherited mapper as canonical and publish read-only room and route snapshots until write-back compatibility is proven.

COMMIT: `git add -A && git commit -m "[EP-013][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Mapper, World Graph, and Routing, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-013-mapper-world-graph-and-routing.md`
- `.agent/node-contracts/EP-013.md`
- `.agent/milestone-files/EP-013-M5.txt`
- `.agent/expected-files/EP-013.txt`
- `.agent/expected-files/EP-013.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-013-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-013` at `tests/live-fire/LF-013-mapper-route-roundtrip.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-013`
2. `sh scripts/record-evidence.sh EP-013 M5 "EP-013 M5: ok" -- sh scripts/node-verifiers/EP-013.sh M5`
3. `sh scripts/scope-audit.sh EP-013`

EXPECT:
- `EP-013 M5: ok`
- `scope audit EP-013: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-013 MILESTONE_PASS "M5 EP-013 M5: ok; evidence=.agent/state/evidence/EP-013/M5"`

FALLBACK: Use the inherited mapper as canonical and publish read-only room and route snapshots until write-back compatibility is proven.

COMMIT: `git add -A && git commit -m "[EP-013][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-013` and require `node verify EP-013: ok`. Then run `sh scripts/expected-files-audit.sh EP-013`, `sh scripts/scope-audit.sh EP-013`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [x] M3: Real integration and user-visible flow
- [x] M4: Forced failures, abuse cases, performance, and operations
- [ ] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

- 2026-08-27: Inherited TAstar.h contains no `class TAstar`; it supplies boost graph A* primitives (`astar_search`, `distance_heuristic`, `astar_goal_visitor`) consumed at src/TMap.cpp:1011. Evidence WM-SRC-000097.
- 2026-08-27: Inherited TRoom models exit locks, special exit locks, exit weights, doors, and exit stubs directly (WM-FEAT-0166 needs no new room model). Evidence WM-SRC-000095.
- 2026-08-27: source_evidence.py still assigns len(existing)+1 (line 73); with 91 rows and max ID 000093 it would have collided. EP-013 M1 evidence recorded via explicit max+1 (000094..000100), checker green at rows=98.

# 13. Decision Log

- 2026-08-27: Mapper integration boundary is namespaced `src/wiremudder/mapper/` plus `wirecore/crates/wire-world-graph/`; inherited mapper stays canonical and unedited unless a discovered-path amendment proves an exact edit is required. Evidence: WM-SRC-000094..000100; contract EP-013 authorized boundaries. Alternatives: patching TMap/TRoom directly. Consequence: no brownfield edit needed for M1; read-only integration. Reversal: add discovered amendment + revert boundary. Affects WM-FEAT-0165..0168, WM-SPEC-012-R04. Security/privacy/license/compatibility/performance: no new authority, no egress, GPL-consistent, no perf impact.
- 2026-08-27: World-graph events and derived-fact provenance (WM-SPEC-012-R02/R03/R10) live in the wire-world-graph crate with versioned schemas under `schemas/wiremudder/world/`; the in-memory hot cache (R03) stays bounded with asynchronous durable writes. Alternatives: putting events in TMap. Consequence: inherited authority preserved. Reversal: move schema into crate. Affects WM-SPEC-012-R02/R03/R10.
- 2026-08-27: Ambiguous room identity (WM-SPEC-012-R05) is preserved as uncertain state with a correction request path; no silent room merge. Alternatives: auto-merge on similarity. Consequence: matches contract. Reversal: none without spec change.
- 2026-08-27: Evidence recorder ID bug handled by bypassing source_evidence.py for this batch: explicit max+1 IDs, same JSONL schema, checker green. Alternatives: run recorder then renumber. Consequence: no clobbered records. Reversal: none.
- 2026-08-27: M2 core behavior implemented as dual implementations (Rust wire-world-graph crate + C++ WorldGraphQt boundary) with identical deterministic invariants; 17 Rust unit tests + 10 C++ invariant groups + schema contract tests green. Routing is deterministic Dijkstra with weights, one-way/hidden/locked/timed semantics. Alternatives: single implementation only. Consequence: cross-implementation parity oracle for M3. Reversal: revert M2 commit.
- 2026-08-27: Derived-fact provenance and corrections (R02/R10) implemented in both cores: corrections supersede facts (superseded_by) while preserving history in a corrections list; ambiguous identity never merges rooms (R05).
- 2026-08-27: M3 integration uses a cross-implementation parity oracle: Rust world_matrix example vs C++ mapper_parity harness produce 13 identical decisions (route, one-way, locked, hidden, timed, weighted, zones, round-trip, facts). E2E route round-trip persists a versioned snapshot through real file IO and asserts determinism across runs. Compatibility fixture `compatibility/maps/fixture-001-reference.map.json` added (SPEC-021).
- 2026-08-27: M4 failure suite proves room/exit limits, malformed snapshot rejection, typed no-path/budget errors. Route budget is a per-graph field defaulting to MAX_ROUTE_NODES (backward-compatible via serde default) so bounded-work tests can set small budgets. Security suite proves secret-sensitivity survives round-trip, hidden-exit policy denial with opt-in, injection-shaped names/commands round-trip as data, tampered snapshots rejected. Performance: 10,000-room grid, p95 routing latency under 10 ms budget with JSON evidence.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.
