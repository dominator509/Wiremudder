NODE-META-BEGIN
ID: EP-032
DEPS: EP-009,EP-015,EP-023,EP-024,EP-025,EP-026
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-032
VERIFY_SENTINEL: node verify EP-032: ok
GREEN_TAG: green/EP-032
NODE-META-END

# 1. Purpose and Big Picture

Run the full performance constitution, establish hardware baselines, enforce P0/P1 budgets, validate queue behavior and session fairness, and prove degradation of every optional subsystem.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-032.md`.
- Own features: WM-FEAT-0131, WM-FEAT-0134, WM-FEAT-0135, WM-FEAT-0136, WM-FEAT-0137, WM-FEAT-0138, WM-FEAT-0139, WM-FEAT-0140, WM-FEAT-0141, WM-FEAT-0142, WM-FEAT-0143, WM-FEAT-0144, plus 2 more rows in FEATURES.tsv.
- Own requirements: WM-SPEC-002-R07, WM-SPEC-002-R09, WM-SPEC-004-R12, WM-SPEC-019-R10, WM-SPEC-027-R06.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-009, EP-015, EP-023, EP-024, EP-025, EP-026. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-032.md`
- `.agent/expected-files/EP-032.txt`
- `.agent/expected-files/EP-032.discovered.txt`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-032.txt`. The milestone fence is `.agent/milestone-files/EP-032-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-032.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-032-performance-benchmarks-degradation-and-fairness.md`
- `.agent/node-contracts/EP-032.md`
- `.agent/expected-files/EP-032.txt`
- `.agent/expected-files/EP-032.discovered.txt`
- `.agent/milestone-files/EP-032-M1.txt`
- `.agent/milestone-files/EP-032-M2.txt`
- `.agent/milestone-files/EP-032-M3.txt`
- `.agent/milestone-files/EP-032-M4.txt`
- `.agent/milestone-files/EP-032-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-032/`
- `scripts/node-verifiers/EP-032.sh`
- `tests/live-fire/LF-032-performance-priority-flood.sh`
- `tests/wiremudder/ep032/`
- `docs/wiremudder/performance/`
- `benchmarks/wiremudder/`
- `tests/wiremudder/performance/`
- `tools/perf-capture/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-032.md`.
- Accepted specifications: SPEC-004, SPEC-027.
- Live-fire: `LF-032` `performance-priority-flood`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Performance, Benchmarks, Degradation, and Fairness.

READ:
- `.agent/execplans/EP-032-performance-benchmarks-degradation-and-fairness.md`
- `.agent/node-contracts/EP-032.md`
- `.agent/milestone-files/EP-032-M1.txt`
- `.agent/expected-files/EP-032.txt`
- `.agent/expected-files/EP-032.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-032-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0131, WM-FEAT-0134, WM-FEAT-0135, WM-FEAT-0136, WM-FEAT-0137, WM-FEAT-0138, WM-FEAT-0139, WM-FEAT-0140, WM-FEAT-0141, WM-FEAT-0142, WM-FEAT-0143, WM-FEAT-0144, plus 2 more rows in FEATURES.tsv.
3. Review owned requirements: WM-SPEC-002-R07, WM-SPEC-002-R09, WM-SPEC-004-R12, WM-SPEC-019-R10, WM-SPEC-027-R06.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-032`
2. `sh scripts/record-evidence.sh EP-032 M1 "EP-032 M1: ok" -- sh scripts/node-verifiers/EP-032.sh M1`
3. `sh scripts/scope-audit.sh EP-032`

EXPECT:
- `EP-032 M1: ok`
- `scope audit EP-032: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-032 MILESTONE_PASS "M1 EP-032 M1: ok; evidence=.agent/state/evidence/EP-032/M1"`

FALLBACK: Disable all P2-P4 features and establish a core baseline; re-enable one optional subsystem at a time only after its budget passes.

COMMIT: `git add -A && git commit -m "[EP-032][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Performance, Benchmarks, Degradation, and Fairness inside namespaced boundaries.

READ:
- `.agent/execplans/EP-032-performance-benchmarks-degradation-and-fairness.md`
- `.agent/node-contracts/EP-032.md`
- `.agent/milestone-files/EP-032-M2.txt`
- `.agent/expected-files/EP-032.txt`
- `.agent/expected-files/EP-032.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-032-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-032`
2. `sh scripts/record-evidence.sh EP-032 M2 "EP-032 M2: ok" -- sh scripts/node-verifiers/EP-032.sh M2`
3. `sh scripts/scope-audit.sh EP-032`

EXPECT:
- `EP-032 M2: ok`
- `scope audit EP-032: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-032 MILESTONE_PASS "M2 EP-032 M2: ok; evidence=.agent/state/evidence/EP-032/M2"`

FALLBACK: Disable all P2-P4 features and establish a core baseline; re-enable one optional subsystem at a time only after its budget passes.

COMMIT: `git add -A && git commit -m "[EP-032][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Performance, Benchmarks, Degradation, and Fairness with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-032-performance-benchmarks-degradation-and-fairness.md`
- `.agent/node-contracts/EP-032.md`
- `.agent/milestone-files/EP-032-M3.txt`
- `.agent/expected-files/EP-032.txt`
- `.agent/expected-files/EP-032.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-032-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-032`
2. `sh scripts/record-evidence.sh EP-032 M3 "EP-032 M3: ok" -- sh scripts/node-verifiers/EP-032.sh M3`
3. `sh scripts/scope-audit.sh EP-032`

EXPECT:
- `EP-032 M3: ok`
- `scope audit EP-032: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-032 MILESTONE_PASS "M3 EP-032 M3: ok; evidence=.agent/state/evidence/EP-032/M3"`

FALLBACK: Disable all P2-P4 features and establish a core baseline; re-enable one optional subsystem at a time only after its budget passes.

COMMIT: `git add -A && git commit -m "[EP-032][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Performance, Benchmarks, Degradation, and Fairness deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-032-performance-benchmarks-degradation-and-fairness.md`
- `.agent/node-contracts/EP-032.md`
- `.agent/milestone-files/EP-032-M4.txt`
- `.agent/expected-files/EP-032.txt`
- `.agent/expected-files/EP-032.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-032-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-032`
2. `sh scripts/record-evidence.sh EP-032 M4 "EP-032 M4: ok" -- sh scripts/node-verifiers/EP-032.sh M4`
3. `sh scripts/scope-audit.sh EP-032`

EXPECT:
- `EP-032 M4: ok`
- `scope audit EP-032: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-032 MILESTONE_PASS "M4 EP-032 M4: ok; evidence=.agent/state/evidence/EP-032/M4"`

FALLBACK: Disable all P2-P4 features and establish a core baseline; re-enable one optional subsystem at a time only after its budget passes.

COMMIT: `git add -A && git commit -m "[EP-032][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Performance, Benchmarks, Degradation, and Fairness, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-032-performance-benchmarks-degradation-and-fairness.md`
- `.agent/node-contracts/EP-032.md`
- `.agent/milestone-files/EP-032-M5.txt`
- `.agent/expected-files/EP-032.txt`
- `.agent/expected-files/EP-032.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-032-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-032` at `tests/live-fire/LF-032-performance-priority-flood.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-032`
2. `sh scripts/record-evidence.sh EP-032 M5 "EP-032 M5: ok" -- sh scripts/node-verifiers/EP-032.sh M5`
3. `sh scripts/scope-audit.sh EP-032`

EXPECT:
- `EP-032 M5: ok`
- `scope audit EP-032: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-032 MILESTONE_PASS "M5 EP-032 M5: ok; evidence=.agent/state/evidence/EP-032/M5"`

FALLBACK: Disable all P2-P4 features and establish a core baseline; re-enable one optional subsystem at a time only after its budget passes.

COMMIT: `git add -A && git commit -m "[EP-032][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-032` and require `node verify EP-032: ok`. Then run `sh scripts/expected-files-audit.sh EP-032`, `sh scripts/scope-audit.sh EP-032`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

# 10. Idempotence and Recovery

Resume cold by running the boot sequence, confirming the lease, reading Progress, discoveries, decisions, outcomes, and the ledger tail, then re-running the last checked milestone sentinel. Provisioning, migrations, imports, updates, event consumption, provider calls, and external effects are idempotent or have explicit detection and compensation. Roll back under LOOPS.md and never cross a completed green tag.

# 11. Progress

- [x] M1: Evidence, contracts, and exact path lock
- [x] M2: Core behavior and deterministic invariants
- [x] M3: Real integration and user-visible flow
- [x] M4: Forced failures, abuse cases, performance, and operations
- [x] M5: Live-fire, evidence closure, and green tag readiness

# 12. Surprises and Discoveries

Append dated evidence-backed discoveries. Speculation is not a discovery.

- 2026-08-28 (M1): EP-032 owns 14 feature rows (WM-FEAT-0131, 0134..0145, 0163) and 5 requirements (WM-SPEC-002-R07, 002-R09, 004-R12, 019-R10, 027-R06). All four authorized boundaries (benchmarks/wiremudder/, tests/wiremudder/performance/, docs/wiremudder/performance/, tools/perf-capture/) are NEW paths -- unlike EP-030/031, this node requires no inherited-source edit and no discovered-path amendment (discovered rows=0).
- 2026-08-28 (M1): The per-crate perf fixture pattern already exists across the owned subsystems (wire-renderer, wire-voice, wire-replay, wire-import, wire-bug-automation, wire-soundscape all ship examples/perf_fixture.rs). EP-032's job is to orchestrate them reproducibly (benchmarks/wiremudder), capture raw artifacts (tools/perf-capture), and enforce budgets -- not to create fixtures from scratch.
- 2026-08-28 (M1): The performance constitution (PERFORMANCE_CONSTITUTION.md) is the binding policy: P0 never waits on optional work, every queue has capacity/priority/overflow/latency/drop/owner, one session cannot starve another, and target budgets are input < 5 ms, outbound < 10 ms, terminal append < 10 ms, emergency stop < 10 ms, renderer 4-6 ms/frame. R12/R06 demand distributions, hardware profile, workload, raw artifacts, and regression thresholds -- no single anecdotal timings.
- 2026-08-28 (M2): The owned crate perf fixtures print distributions in three different real formats: `p50_us=.. p95_us=.. max_us=..` (wire-import), `p50=..us p95=..us worst=..us` (wire-replay), and mean-only `mean_us=..` (wire-soundscape). The perf-capture parser must accept all three. It initially took the LAST distribution line, which understated the worst path (bug-automation prints redact/transit/route and route is 0us); the parser now enforces the WORST observed path per SPEC-004-R12 by taking the line with the largest max_us -- a real defect found and fixed by running against the real fixtures.
- 2026-08-28 (M2): rustc here does not support `{fx.example}` field-access format capture; positional `{0}` is required. Also, `cargo` is wrapped by rtk-tee which logs failures but still compiles; real errors surface in the log file.
- 2026-08-28 (M3): The priority-flood e2e proves the constitution prime directive with real numbers: a 2000-item P3 renderer-emit flood coalesces 1992 items at its bounded capacity while the P0 outbound queue processes all 2000 items with zero drops and budget met. P3 backpressure never propagates into P0 (WM-SPEC-004-R04/R09).
- 2026-08-28 (M4): The failure harness's duplicate/replay case initially asserted 24 processed on a capacity-8 queue with Drop policy; the real bounded behavior is 8 processed + 16 dropped. The test was corrected to assert the real invariant (capacity-bounded idempotence, no panic) -- the model was right, the test expectation was wrong.

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

- 2026-08-28 (M1): Adopt the performance constitution as the binding oracle for this node: every benchmark must report distributions (p50/p95/max), hardware profile, workload, raw artifacts, and regression thresholds per WM-SPEC-004-R12 and WM-SPEC-027-R06. Evidence: WM-SRC-000231..000242. Alternatives: single-sample timings rejected by R12 explicitly. Consequence: every perf fixture output is captured into raw artifacts under tools/perf-capture. Reversal: revert the benchmark harness. Affects WM-SPEC-004-R12, WM-SPEC-027-R06, WM-FEAT-0131..0139; security/privacy neutral.
- 2026-08-28 (M1): Orchestrate the existing per-crate perf fixtures through a new benchmarks/wiremudder harness rather than duplicating fixtures. Evidence: perf_fixture.rs in wire-renderer/voice/replay/import/bug-automation/soundscape (WM-SRC-000240..000241). Alternatives: new standalone benchmarks rejected as duplication of the established pattern. Consequence: reproducible driver + raw artifact capture across all owned crates. Reversal: remove the harness and tool. Affects WM-FEAT-0131; performance only.
- 2026-08-28 (M2): Implement the SPEC-004 model as a deterministic Rust crate (benchmarks/wiremudder): PriorityRing P0..P4, Budget (time/memory/cancelable), BoundedQueue with the seven overflow policies (Process/Coalesce/Drop/Defer/Pause/Disable/Quarantine) and observed metrics (processed/dropped/coalesced/deferred/quarantined, p50/p95/max), FairnessGovernor (per-session max share + round reset), DegradationState (always preserves raw text), and the R12 BenchmarkArtifact shape (hardware, workload, runs, regression thresholds, raw_evidence). Evidence: 9/9 deterministic unit tests. Alternatives: a timer-based model rejected for nondeterminism; a separate monitoring daemon rejected as out of scope (node is benchmarks + budgets). Consequence: the constitution rules become testable invariants. Reversal: remove the crate. Affects WM-FEAT-0134/0135/0138/0141; security/privacy neutral.
- 2026-08-28 (M2): Build tools/perf-capture as the reproducible driver: it runs each owned crate's perf fixture in release mode, parses the real measured distribution (all three formats), enforces worst-observed budget per R12, and writes a suite raw artifact (hardware, workload, runs, regression thresholds, raw_evidence=true). Evidence: run of all 6 fixtures with budgets met (renderer p95 34us/6ms, voice 14us/5ms, import 13us/5ms, replay 216us/5ms, bug-automation <=8us/5ms, soundscape 2us/5ms). Alternatives: writing a new benchmark framework rejected -- the constitution's fixtures already exist per crate. Consequence: raw artifacts at tools/perf-capture/artifacts/ feed the M4 perf test and M5 live-fire. Reversal: remove the tool. Affects WM-FEAT-0131/0138/0142/0143/0144; security/privacy neutral.
- 2026-08-28 (M3): Prove real integration through the production crate binaries: perf-capture drives all six owned fixtures end to end with raw artifact integrity checks, the model-core harness exercises P0/P1/P3 queues + fairness + quarantine through the real crate, and the priority-flood e2e shows P0 survives a P3 flood (2000 processed, 0 dropped, 1992 coalesced). Evidence: integration/perf-capture-driver.sh, integration/model-core.sh, e2e/priority-flood.sh; design doc at docs/wiremudder/performance/design/benchmarks.md. Alternatives: none -- the node's own acceptance obligation 3/4 (queue overflow matches contracts, no session starvation) require exactly this. Consequence: constitution rules proven against real binaries. Reversal: remove M3 tests/docs. Affects WM-FEAT-0134/0135/0142; security/privacy neutral.
- 2026-08-28 (M4): Prove fail-closed under abuse with real controlled harnesses: (1) failure matrix -- 100k-item P0 flood stays at capacity 16 with budget met, 10k-item quarantine overflow, P3 drop overflow (96/100 dropped), idempotent replays, fairness quota denial, drain compensation, degradation invariants; (2) security matrix -- model has no network/process/secret/authority references, perf-capture only spawns cargo for owned manifests and constrains artifact writes to out_dir; (3) performance regression gate -- all six subsystems inside thresholds (renderer 34us/6ms, voice 14us/5ms, import 11us/5ms, replay 201us/5ms, bug-automation <=18us/5ms, soundscape 3us/5ms); (4) ops runbook. Evidence: failure/security/performance tests + runbook. Alternatives: weakening budgets rejected by R10; mocking rejected by the real-controlled-failure rule. Consequence: P0/P1 budgets enforced with distributions; fail-closed posture proven. Reversal: remove M4 test dirs. Affects WM-FEAT-0134..0145/0163; security/privacy neutral.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

## EP-032 Outcomes (2026-08-28)

- Changed vs expected: all changes inside the static fence; no discovered
  amendment (rows=0 -- all four boundaries are new paths). Changed files
  per milestone: M1 8, M2 13, M3 8, M4 8, M5 ~40 (14 feature tests + 5
  requirement tests + LF + verifier + ledger).
- Source evidence: WM-SRC-000231..000242 (SPEC-004/027 anchors, feature
  rows, constitution, crate perf infrastructure, boundary anchors).
- Commands and observed sentinels:
  - `sh scripts/node-verifiers/EP-032.sh M1..M5` -> `EP-032 M{1..5}: ok`
  - `sh scripts/live-fire/LF-032-performance-priority-flood.sh` ->
    `LF-032: ok` (obligations 1..6 true; flood=5000 coalesced=4992
    voice_dropped=4996 p0_processed=5000)
  - `sh scripts/node-contract-check.sh EP-032` -> `node contract check EP-032: ok`
  - `sh scripts/scope-audit.sh EP-032` -> `scope audit EP-032: ok changed=50`
  - Expected-files audit passed inside M5 verifier.
- Feature disposition: 14/14 owned features implemented and tested
  (WM-FEAT-0131, 0134..0145, 0163) -- benchmark suite, priority rings,
  bounded queues, metrics, degradation, quarantine, budgets.
- Requirement disposition: 5/5 owned requirements satisfied
  (WM-SPEC-002-R07/R09, WM-SPEC-004-R12, WM-SPEC-019-R10,
  WM-SPEC-027-R06) with 5-level depth tests.
- Provider/platform certification: no external provider; real measured
  distributions on x86_64 linux; all six owned subsystems inside budgets.
- Assumptions changed: none.
- Risks: none open. Worst observed p95 across owned subsystems was
  replay-batch 201-216us, far inside the 5ms budget.
- Rollback: remove benchmarks/wiremudder/, tools/perf-capture/,
  tests/wiremudder/ep032/, tests/wiremudder/performance/,
  docs/wiremudder/performance/. No inherited path touched.
- Green tag: `green/EP-032` (created after `node verify EP-032: ok`).
- Next scheduler output: per `scripts/graph-next.sh` after lease release.
