NODE-META-BEGIN
ID: EP-028
DEPS: EP-003,EP-006,EP-014
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-028
VERIFY_SENTINEL: node verify EP-028: ok
GREEN_TAG: green/EP-028
NODE-META-END

# 1. Purpose and Big Picture

Implement local structured telemetry, ring buffers, redaction, fingerprints, session replay, diagnostic preview/export, health metrics, and sanitized fixture generation.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-028.md`.
- Own features: WM-FEAT-0128, WM-FEAT-0132, WM-FEAT-0221, WM-FEAT-0223, WM-FEAT-0224, WM-FEAT-0225, WM-FEAT-0227.
- Own requirements: WM-SPEC-011-R03, WM-SPEC-011-R10, WM-SPEC-019-R01, WM-SPEC-019-R03, WM-SPEC-023-R05, WM-SPEC-024-R09, WM-SPEC-025-R02, WM-SPEC-026-R07, WM-SPEC-026-R08.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-003, EP-006, EP-014. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-028.md`
- `.agent/expected-files/EP-028.txt`
- `.agent/expected-files/EP-028.discovered.txt`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-028.txt`. The milestone fence is `.agent/milestone-files/EP-028-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-028.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-028-telemetry-replay-and-diagnostic-bundles.md`
- `.agent/node-contracts/EP-028.md`
- `.agent/expected-files/EP-028.txt`
- `.agent/expected-files/EP-028.discovered.txt`
- `.agent/milestone-files/EP-028-M1.txt`
- `.agent/milestone-files/EP-028-M2.txt`
- `.agent/milestone-files/EP-028-M3.txt`
- `.agent/milestone-files/EP-028-M4.txt`
- `.agent/milestone-files/EP-028-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-028/`
- `scripts/node-verifiers/EP-028.sh`
- `tests/live-fire/LF-028-diagnostic-bundle-redaction.sh`
- `tests/wiremudder/ep028/`
- `docs/wiremudder/diagnostics/`
- `wirecore/crates/wire-telemetry/`
- `wirecore/crates/wire-replay/`
- `src/wiremudder/ui/diagnostics/`
- `schemas/wiremudder/telemetry/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-028.md`.
- Accepted specifications: SPEC-010, SPEC-019, SPEC-023, SPEC-026.
- Live-fire: `LF-028` `diagnostic-bundle-redaction`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Telemetry, Replay, and Diagnostic Bundles.

READ:
- `.agent/execplans/EP-028-telemetry-replay-and-diagnostic-bundles.md`
- `.agent/node-contracts/EP-028.md`
- `.agent/milestone-files/EP-028-M1.txt`
- `.agent/expected-files/EP-028.txt`
- `.agent/expected-files/EP-028.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-028-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0128, WM-FEAT-0132, WM-FEAT-0221, WM-FEAT-0223, WM-FEAT-0224, WM-FEAT-0225, WM-FEAT-0227.
3. Review owned requirements: WM-SPEC-011-R03, WM-SPEC-011-R10, WM-SPEC-019-R01, WM-SPEC-019-R03, WM-SPEC-023-R05, WM-SPEC-024-R09, WM-SPEC-025-R02, WM-SPEC-026-R07, WM-SPEC-026-R08.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-028`
2. `sh scripts/record-evidence.sh EP-028 M1 "EP-028 M1: ok" -- sh scripts/node-verifiers/EP-028.sh M1`
3. `sh scripts/scope-audit.sh EP-028`

EXPECT:
- `EP-028 M1: ok`
- `scope audit EP-028: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-028 MILESTONE_PASS "M1 EP-028 M1: ok; evidence=.agent/state/evidence/EP-028/M1"`

FALLBACK: Keep local crash logs and manual text export only, with replay and external submission disabled.

COMMIT: `git add -A && git commit -m "[EP-028][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Telemetry, Replay, and Diagnostic Bundles inside namespaced boundaries.

READ:
- `.agent/execplans/EP-028-telemetry-replay-and-diagnostic-bundles.md`
- `.agent/node-contracts/EP-028.md`
- `.agent/milestone-files/EP-028-M2.txt`
- `.agent/expected-files/EP-028.txt`
- `.agent/expected-files/EP-028.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-028-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-028`
2. `sh scripts/record-evidence.sh EP-028 M2 "EP-028 M2: ok" -- sh scripts/node-verifiers/EP-028.sh M2`
3. `sh scripts/scope-audit.sh EP-028`

EXPECT:
- `EP-028 M2: ok`
- `scope audit EP-028: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-028 MILESTONE_PASS "M2 EP-028 M2: ok; evidence=.agent/state/evidence/EP-028/M2"`

FALLBACK: Keep local crash logs and manual text export only, with replay and external submission disabled.

COMMIT: `git add -A && git commit -m "[EP-028][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Telemetry, Replay, and Diagnostic Bundles with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-028-telemetry-replay-and-diagnostic-bundles.md`
- `.agent/node-contracts/EP-028.md`
- `.agent/milestone-files/EP-028-M3.txt`
- `.agent/expected-files/EP-028.txt`
- `.agent/expected-files/EP-028.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-028-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-028`
2. `sh scripts/record-evidence.sh EP-028 M3 "EP-028 M3: ok" -- sh scripts/node-verifiers/EP-028.sh M3`
3. `sh scripts/scope-audit.sh EP-028`

EXPECT:
- `EP-028 M3: ok`
- `scope audit EP-028: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-028 MILESTONE_PASS "M3 EP-028 M3: ok; evidence=.agent/state/evidence/EP-028/M3"`

FALLBACK: Keep local crash logs and manual text export only, with replay and external submission disabled.

COMMIT: `git add -A && git commit -m "[EP-028][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Telemetry, Replay, and Diagnostic Bundles deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-028-telemetry-replay-and-diagnostic-bundles.md`
- `.agent/node-contracts/EP-028.md`
- `.agent/milestone-files/EP-028-M4.txt`
- `.agent/expected-files/EP-028.txt`
- `.agent/expected-files/EP-028.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-028-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-028`
2. `sh scripts/record-evidence.sh EP-028 M4 "EP-028 M4: ok" -- sh scripts/node-verifiers/EP-028.sh M4`
3. `sh scripts/scope-audit.sh EP-028`

EXPECT:
- `EP-028 M4: ok`
- `scope audit EP-028: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-028 MILESTONE_PASS "M4 EP-028 M4: ok; evidence=.agent/state/evidence/EP-028/M4"`

FALLBACK: Keep local crash logs and manual text export only, with replay and external submission disabled.

COMMIT: `git add -A && git commit -m "[EP-028][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Telemetry, Replay, and Diagnostic Bundles, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-028-telemetry-replay-and-diagnostic-bundles.md`
- `.agent/node-contracts/EP-028.md`
- `.agent/milestone-files/EP-028-M5.txt`
- `.agent/expected-files/EP-028.txt`
- `.agent/expected-files/EP-028.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md`
- `.agent/specs/SPEC-023-data-model-and-retention.md`
- `.agent/specs/SPEC-026-observability-operations-and-diagnostics.md`

CHANGE: exact paths in `.agent/milestone-files/EP-028-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-028` at `tests/live-fire/LF-028-diagnostic-bundle-redaction.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-028`
2. `sh scripts/record-evidence.sh EP-028 M5 "EP-028 M5: ok" -- sh scripts/node-verifiers/EP-028.sh M5`
3. `sh scripts/scope-audit.sh EP-028`

EXPECT:
- `EP-028 M5: ok`
- `scope audit EP-028: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-028 MILESTONE_PASS "M5 EP-028 M5: ok; evidence=.agent/state/evidence/EP-028/M5"`

FALLBACK: Keep local crash logs and manual text export only, with replay and external submission disabled.

COMMIT: `git add -A && git commit -m "[EP-028][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-028` and require `node verify EP-028: ok`. Then run `sh scripts/expected-files-audit.sh EP-028`, `sh scripts/scope-audit.sh EP-028`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

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

- 2026-08-28: The first redactor implementation used a while-loop that re-matched its own replacement (`password=[REDACTED]` still contains `password=`), causing an infinite loop during tests. Replaced with a single-pass scanner that consumes the marker itself (evidence: wire-telemetry tests, M2).
- 2026-08-28: `serde_json::Map::len()` counts entries, not bytes -- the detail-payload size bound was never enforced until the M4 failure matrix exposed it. Fixed by measuring serialized byte length (evidence: failure_matrix, M4).
- 2026-08-28: The corpus stripped the word "player" but not actual player names. SPEC-019-R05 requires stripping player names; the honest mechanism is `FixtureGenerator::with_player_names` -- the caller supplies known names from profile/world scope (evidence: security_matrix, M4).
- 2026-08-28: Live-fire LF-028 found a real leak: "Your token is hunter2-f00" -- the redactor consumed only the adjacent token after the marker (`is`), leaving the secret value exposed. The value span now runs to the sentence boundary; over-redaction is accepted over secret leakage (evidence: LF-028, M5).

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

- 2026-08-28: Architecture -- telemetry/replay implemented as two isolated WireCore crates (`wire-telemetry`, `wire-replay`) with canonical schemas under `schemas/wiremudder/telemetry/`, a passive Qt6 diagnostics UI boundary, and LF-028 live-fire. Evidence: WM-SRC-000186..192; node contract EP-028. Alternative: single combined crate -- rejected to keep ring-buffer capture separate from deterministic replay and bundles. Consequence: narrow, testable boundaries. Reversal: delete crates and revert CMakeLists. Affects WM-FEAT-0128/0132/0221/0223/0224/0225/0227. Privacy: telemetry off by default, redaction corpus, no hosted endpoint. Compatibility: schemas versioned const 1; replay deterministic. Performance: SPEC-004 budgets measured in M4.
- 2026-08-28: Inherited integration -- `src/CMakeLists.txt` is the only inherited edit, via discovered amendment WM-SRC-000186, wiring `src/wiremudder/ui/diagnostics/` into `mudlet_SRCS` exactly beside the soundscape/help panes. Alternative: separate shared library -- rejected (inherited client compiles all UI sources in one list). Rollback: `git checkout -- src/CMakeLists.txt`.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

- Milestones: M1..M5 all pass `EP-028 Mk: ok`; `node verify EP-028: ok`.
- Changed vs expected: static fence 23 paths; discovered amendment `src/CMakeLists.txt` (WM-SRC-000186); scope audit ok.
- Source evidence: WM-SRC-000186..192 (CMake anchor, telemetry schema, replay schema, SPEC-019/023/026 anchors, UI boundary pattern).
- Commands: `sh scripts/node-verifiers/EP-028.sh M1..M5,verify`; `cargo test` wire-telemetry 11/11, wire-replay 8/8; `cargo run --example e2e_diagnostics|failure_matrix|security_matrix|perf_fixture|lf028_live`.
- Sentinels: `EP-028 M1: ok` .. `EP-028 M5: ok`, `node verify EP-028: ok`, `LF-028 diagnostic-bundle-redaction: ok`.
- Performance (release, this host): ring-record p50=1us p95=2us worst=231us; ring-raw worst=109us; redaction worst=60us; replay-hash worst=640us; bundle-build worst=269us; budget 5000us (SPEC-004) -- all green.
- Features: WM-FEAT-0128, WM-FEAT-0132, WM-FEAT-0221, WM-FEAT-0223, WM-FEAT-0224, WM-FEAT-0225, WM-FEAT-0227 all implemented and certified by feature tests + LF-028.
- Requirements: WM-SPEC-011-R03, WM-SPEC-011-R10, WM-SPEC-019-R01, WM-SPEC-019-R03, WM-SPEC-023-R05, WM-SPEC-024-R09, WM-SPEC-025-R02, WM-SPEC-026-R07, WM-SPEC-026-R08 all green.
- Real findings fixed in code (never weakened): redactor infinite loop; detail byte bound; player-name stripping; sentence-boundary redaction.
- Green tag: `green/EP-028`.
- Scheduler next: EP-029 (deps EP-022, EP-028).
