NODE-META-BEGIN
ID: EP-003
DEPS: EP-002
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-003
VERIFY_SENTINEL: node verify EP-003: ok
GREEN_TAG: green/EP-003
NODE-META-END

# 1. Purpose and Big Picture

Build the independent reference harness, controlled fake MUD servers, trace normalization, sanitized profile/package/map corpus, differential comparison, replay format, and evidence rules that prevent implementation and tests from sharing the same hallucination.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-003.md`.
- Own features: WM-FEAT-0126, WM-FEAT-0129, WM-FEAT-0130.
- Own requirements: WM-SPEC-003-R03, WM-SPEC-003-R04, WM-SPEC-003-R05, WM-SPEC-003-R06, WM-SPEC-003-R09, WM-SPEC-005-R06, WM-SPEC-005-R08, WM-SPEC-005-R10, WM-SPEC-006-R01, WM-SPEC-006-R02, WM-SPEC-006-R03, WM-SPEC-006-R07, plus 20 more rows in VALIDATION_MATRIX.tsv.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-002. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-003.md`
- `.agent/expected-files/EP-003.txt`
- `.agent/expected-files/EP-003.discovered.txt`
- `.agent/specs/SPEC-003-canonical-vocabulary-events-and-capabilities.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-003.txt`. The milestone fence is `.agent/milestone-files/EP-003-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-003.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-003-compatibility-oracle-protocol-museum-and-replay.md`
- `.agent/node-contracts/EP-003.md`
- `.agent/expected-files/EP-003.txt`
- `.agent/expected-files/EP-003.discovered.txt`
- `.agent/milestone-files/EP-003-M1.txt`
- `.agent/milestone-files/EP-003-M2.txt`
- `.agent/milestone-files/EP-003-M3.txt`
- `.agent/milestone-files/EP-003-M4.txt`
- `.agent/milestone-files/EP-003-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-003/`
- `scripts/node-verifiers/EP-003.sh`
- `tests/live-fire/LF-003-compatibility-oracle-roundtrip.sh`
- `tests/wiremudder/ep003/`
- `docs/wiremudder/compatibility/`
- `compatibility/framework/`
- `compatibility/replay/`
- `compatibility/protocol-museum/`
- `tests/wiremudder/oracle/`
- `tools/protocol-museum/`
- `schemas/wiremudder/replay/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-003.md`.
- Accepted specifications: SPEC-003, SPEC-005, SPEC-006, SPEC-019, SPEC-021, SPEC-027.
- Live-fire: `LF-003` `compatibility-oracle-roundtrip`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Compatibility Oracle, Protocol Museum, and Replay.

READ:
- `.agent/execplans/EP-003-compatibility-oracle-protocol-museum-and-replay.md`
- `.agent/node-contracts/EP-003.md`
- `.agent/milestone-files/EP-003-M1.txt`
- `.agent/expected-files/EP-003.txt`
- `.agent/expected-files/EP-003.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-003-canonical-vocabulary-events-and-capabilities.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-003-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0126, WM-FEAT-0129, WM-FEAT-0130.
3. Review owned requirements: WM-SPEC-003-R03, WM-SPEC-003-R04, WM-SPEC-003-R05, WM-SPEC-003-R06, WM-SPEC-003-R09, WM-SPEC-005-R06, WM-SPEC-005-R08, WM-SPEC-005-R10, WM-SPEC-006-R01, WM-SPEC-006-R02, WM-SPEC-006-R03, WM-SPEC-006-R07, plus 20 more rows in VALIDATION_MATRIX.tsv.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-003`
2. `sh scripts/record-evidence.sh EP-003 M1 "EP-003 M1: ok" -- sh scripts/node-verifiers/EP-003.sh M1`
3. `sh scripts/scope-audit.sh EP-003`

EXPECT:
- `EP-003 M1: ok`
- `scope audit EP-003: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-003 MILESTONE_PASS "M1 EP-003 M1: ok; evidence=.agent/state/evidence/EP-003/M1"`

FALLBACK: Use captured byte streams and headless reference scripts for non-UI behavior while marking visual behaviors blocked until the UI harness is available.

COMMIT: `git add -A && git commit -m "[EP-003][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Compatibility Oracle, Protocol Museum, and Replay inside namespaced boundaries.

READ:
- `.agent/execplans/EP-003-compatibility-oracle-protocol-museum-and-replay.md`
- `.agent/node-contracts/EP-003.md`
- `.agent/milestone-files/EP-003-M2.txt`
- `.agent/expected-files/EP-003.txt`
- `.agent/expected-files/EP-003.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-003-canonical-vocabulary-events-and-capabilities.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-003-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-003`
2. `sh scripts/record-evidence.sh EP-003 M2 "EP-003 M2: ok" -- sh scripts/node-verifiers/EP-003.sh M2`
3. `sh scripts/scope-audit.sh EP-003`

EXPECT:
- `EP-003 M2: ok`
- `scope audit EP-003: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-003 MILESTONE_PASS "M2 EP-003 M2: ok; evidence=.agent/state/evidence/EP-003/M2"`

FALLBACK: Use captured byte streams and headless reference scripts for non-UI behavior while marking visual behaviors blocked until the UI harness is available.

COMMIT: `git add -A && git commit -m "[EP-003][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Compatibility Oracle, Protocol Museum, and Replay with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-003-compatibility-oracle-protocol-museum-and-replay.md`
- `.agent/node-contracts/EP-003.md`
- `.agent/milestone-files/EP-003-M3.txt`
- `.agent/expected-files/EP-003.txt`
- `.agent/expected-files/EP-003.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-003-canonical-vocabulary-events-and-capabilities.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-003-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-003`
2. `sh scripts/record-evidence.sh EP-003 M3 "EP-003 M3: ok" -- sh scripts/node-verifiers/EP-003.sh M3`
3. `sh scripts/scope-audit.sh EP-003`

EXPECT:
- `EP-003 M3: ok`
- `scope audit EP-003: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-003 MILESTONE_PASS "M3 EP-003 M3: ok; evidence=.agent/state/evidence/EP-003/M3"`

FALLBACK: Use captured byte streams and headless reference scripts for non-UI behavior while marking visual behaviors blocked until the UI harness is available.

COMMIT: `git add -A && git commit -m "[EP-003][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Compatibility Oracle, Protocol Museum, and Replay deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-003-compatibility-oracle-protocol-museum-and-replay.md`
- `.agent/node-contracts/EP-003.md`
- `.agent/milestone-files/EP-003-M4.txt`
- `.agent/expected-files/EP-003.txt`
- `.agent/expected-files/EP-003.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-003-canonical-vocabulary-events-and-capabilities.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-003-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-003`
2. `sh scripts/record-evidence.sh EP-003 M4 "EP-003 M4: ok" -- sh scripts/node-verifiers/EP-003.sh M4`
3. `sh scripts/scope-audit.sh EP-003`

EXPECT:
- `EP-003 M4: ok`
- `scope audit EP-003: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-003 MILESTONE_PASS "M4 EP-003 M4: ok; evidence=.agent/state/evidence/EP-003/M4"`

FALLBACK: Use captured byte streams and headless reference scripts for non-UI behavior while marking visual behaviors blocked until the UI harness is available.

COMMIT: `git add -A && git commit -m "[EP-003][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Compatibility Oracle, Protocol Museum, and Replay, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-003-compatibility-oracle-protocol-museum-and-replay.md`
- `.agent/node-contracts/EP-003.md`
- `.agent/milestone-files/EP-003-M5.txt`
- `.agent/expected-files/EP-003.txt`
- `.agent/expected-files/EP-003.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-003-canonical-vocabulary-events-and-capabilities.md`
- `.agent/specs/SPEC-005-inherited-classic-client-compatibility.md`
- `.agent/specs/SPEC-006-network-protocol-and-routing.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-003-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-003` at `tests/live-fire/LF-003-compatibility-oracle-roundtrip.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-003`
2. `sh scripts/record-evidence.sh EP-003 M5 "EP-003 M5: ok" -- sh scripts/node-verifiers/EP-003.sh M5`
3. `sh scripts/scope-audit.sh EP-003`

EXPECT:
- `EP-003 M5: ok`
- `scope audit EP-003: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-003 MILESTONE_PASS "M5 EP-003 M5: ok; evidence=.agent/state/evidence/EP-003/M5"`

FALLBACK: Use captured byte streams and headless reference scripts for non-UI behavior while marking visual behaviors blocked until the UI harness is available.

COMMIT: `git add -A && git commit -m "[EP-003][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-003` and require `node verify EP-003: ok`. Then run `sh scripts/expected-files-audit.sh EP-003`, `sh scripts/scope-audit.sh EP-003`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

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

- 2026-08-27: EP-003 M1 recorded evidence for the compatibility oracle: inherited fake MUD server (TelnetServerStub, WM-SRC-000039/000040), session test (000041), sequence recovery test (000042), mapper round-trip (000043), profile round-trip (000044). Contract tests verify inherited oracle fixtures and namespacing since lease base. Evidence: M1 verifier sentinel. Alternative: building the oracle from scratch rejected (must reuse inherited fixtures where possible). Consequence: the oracle is independent of implementation tests. Reversal: git revert of M1 commit. Affects: WM-FEAT-0126, WM-FEAT-0129, WM-FEAT-0130. Security: no secrets. License: inherited GPL fixtures preserved. Compatibility: oracle boundaries locked. Performance: n/a. Upstream impact: none.
- 2026-08-27: EP-003 M2 implemented the replay schema (schemas/wiremudder/replay/session-replay.schema.json), replay validator (compatibility/replay/replay_validate.py), Protocol Museum fake MUD servers (compatibility/protocol-museum/museum.py with negotiation/text-stream/malformed/latency/disconnect scenarios), sanitization (compatibility/framework/sanitize.py), and oracle recorder (tools/protocol-museum/oracle_record.py). Unit tests prove real TCP captures validate, sanitize deterministically, and replay determinism holds. Evidence: M2 verifier sentinel; unit 001-004; oracle 001. Alternative: none - SPEC-019-R08 requires controlled fake servers; mocks rejected. Consequence: independent reference harness exists for compatibility proofs. Reversal: git revert of M2 commit. Affects: WM-FEAT-0126, WM-FEAT-0129, WM-FEAT-0130, WM-SPEC-019-R04/R05/R07/R08. Security: sanitization strips secrets. License: new MIT-adjacent namespaced code. Compatibility: no inherited edits. Performance: bounded captures. Upstream impact: none.
- 2026-08-27: EP-003 M3 integrated the oracle pipeline end-to-end: all 5 museum scenarios captured over real TCP (negotiation 3 events, text-stream 5, malformed 3, latency 2, disconnect 1), each validated against the replay schema and sanitized; client port probe proves the fixture port serves real connections; differential comparison of two text-stream runs shows identical line streams. Evidence: M3 verifier sentinel; integration 001-002; e2e 001. Alternative: simulated fixtures rejected; real sockets used. Consequence: the compatibility oracle is proven against live protocol traffic. Reversal: git revert of M3 commit. Affects: WM-FEAT-0126, WM-FEAT-0129, WM-FEAT-0130, WM-SPEC-019-R07/R08. Security: sanitized fixtures only. License: n/a. Compatibility: differential determinism proven. Performance: bounded captures. Upstream impact: none.
- 2026-08-27: EP-003 M4 added failure proofs (unknown scenario rejected, validator fail-closed on empty/non-object/missing-direction events, hostile-input sanitization), security proofs (fixture scan over all compatibility sources, loopback-only binding), and performance budgets (oracle capture worst 315ms). Hostile-input testing found and fixed a real sanitizer gap: bare "Bearer <token>" leaked; now redacted. Evidence: M4 verifier sentinel. Alternative: mocks rejected. Consequence: oracle fails closed and sanitizes all token forms. Reversal: git revert of M4 commit. Affects: WM-FEAT-0126, WM-FEAT-0129, WM-FEAT-0130, WM-SPEC-019-R05/R08. Security: bearer tokens redacted; loopback binding proven. License: n/a. Compatibility: no inherited edits. Performance: capture bounded under 10s. Upstream impact: none.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.
