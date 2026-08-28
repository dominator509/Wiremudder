NODE-META-BEGIN
ID: EP-026
DEPS: EP-024,EP-025
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-026
VERIFY_SENTINEL: node verify EP-026: ok
GREEN_TAG: green/EP-026
NODE-META-END

# 1. Purpose and Big Picture

Implement room, area, combat, boss, weather, death, victory, and ambience soundscape bindings, local asset packs, studio controls, transitions, provenance, cancellation, and text-preserving degradation.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-026.md`.
- Own features: WM-FEAT-0075, WM-FEAT-0076.
- Own requirements: WM-SPEC-016-R08.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-024, EP-025. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-026.md`
- `.agent/expected-files/EP-026.txt`
- `.agent/expected-files/EP-026.discovered.txt`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-026.txt`. The milestone fence is `.agent/milestone-files/EP-026-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-026.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-026-soundscape-engine-and-audio-studio.md`
- `.agent/node-contracts/EP-026.md`
- `.agent/expected-files/EP-026.txt`
- `.agent/expected-files/EP-026.discovered.txt`
- `.agent/milestone-files/EP-026-M1.txt`
- `.agent/milestone-files/EP-026-M2.txt`
- `.agent/milestone-files/EP-026-M3.txt`
- `.agent/milestone-files/EP-026-M4.txt`
- `.agent/milestone-files/EP-026-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-026/`
- `scripts/node-verifiers/EP-026.sh`
- `tests/live-fire/LF-026-soundscape-degradation.sh`
- `tests/wiremudder/ep026/`
- `docs/wiremudder/soundscape/`
- `wirecore/crates/wire-soundscape/`
- `src/wiremudder/ui/soundscape/`
- `schemas/wiremudder/audio/`
- `assets/wiremudder/audio/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-026.md`.
- Accepted specifications: SPEC-004, SPEC-015, SPEC-016, SPEC-022.
- Live-fire: `LF-026` `soundscape-degradation`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Soundscape Engine and Audio Studio.

READ:
- `.agent/execplans/EP-026-soundscape-engine-and-audio-studio.md`
- `.agent/node-contracts/EP-026.md`
- `.agent/milestone-files/EP-026-M1.txt`
- `.agent/expected-files/EP-026.txt`
- `.agent/expected-files/EP-026.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-026-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0075, WM-FEAT-0076.
3. Review owned requirements: WM-SPEC-016-R08.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-026`
2. `sh scripts/record-evidence.sh EP-026 M1 "EP-026 M1: ok" -- sh scripts/node-verifiers/EP-026.sh M1`
3. `sh scripts/scope-audit.sh EP-026`

EXPECT:
- `EP-026 M1: ok`
- `scope audit EP-026: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-026 MILESTONE_PASS "M1 EP-026 M1: ok; evidence=.agent/state/evidence/EP-026/M1"`

FALLBACK: Support user-local ambience loops with manual room binding and disable automatic transitions and remote assets.

COMMIT: `git add -A && git commit -m "[EP-026][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Soundscape Engine and Audio Studio inside namespaced boundaries.

READ:
- `.agent/execplans/EP-026-soundscape-engine-and-audio-studio.md`
- `.agent/node-contracts/EP-026.md`
- `.agent/milestone-files/EP-026-M2.txt`
- `.agent/expected-files/EP-026.txt`
- `.agent/expected-files/EP-026.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-026-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-026`
2. `sh scripts/record-evidence.sh EP-026 M2 "EP-026 M2: ok" -- sh scripts/node-verifiers/EP-026.sh M2`
3. `sh scripts/scope-audit.sh EP-026`

EXPECT:
- `EP-026 M2: ok`
- `scope audit EP-026: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-026 MILESTONE_PASS "M2 EP-026 M2: ok; evidence=.agent/state/evidence/EP-026/M2"`

FALLBACK: Support user-local ambience loops with manual room binding and disable automatic transitions and remote assets.

COMMIT: `git add -A && git commit -m "[EP-026][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Soundscape Engine and Audio Studio with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-026-soundscape-engine-and-audio-studio.md`
- `.agent/node-contracts/EP-026.md`
- `.agent/milestone-files/EP-026-M3.txt`
- `.agent/expected-files/EP-026.txt`
- `.agent/expected-files/EP-026.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-026-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-026`
2. `sh scripts/record-evidence.sh EP-026 M3 "EP-026 M3: ok" -- sh scripts/node-verifiers/EP-026.sh M3`
3. `sh scripts/scope-audit.sh EP-026`

EXPECT:
- `EP-026 M3: ok`
- `scope audit EP-026: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-026 MILESTONE_PASS "M3 EP-026 M3: ok; evidence=.agent/state/evidence/EP-026/M3"`

FALLBACK: Support user-local ambience loops with manual room binding and disable automatic transitions and remote assets.

COMMIT: `git add -A && git commit -m "[EP-026][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Soundscape Engine and Audio Studio deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-026-soundscape-engine-and-audio-studio.md`
- `.agent/node-contracts/EP-026.md`
- `.agent/milestone-files/EP-026-M4.txt`
- `.agent/expected-files/EP-026.txt`
- `.agent/expected-files/EP-026.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-026-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-026`
2. `sh scripts/record-evidence.sh EP-026 M4 "EP-026 M4: ok" -- sh scripts/node-verifiers/EP-026.sh M4`
3. `sh scripts/scope-audit.sh EP-026`

EXPECT:
- `EP-026 M4: ok`
- `scope audit EP-026: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-026 MILESTONE_PASS "M4 EP-026 M4: ok; evidence=.agent/state/evidence/EP-026/M4"`

FALLBACK: Support user-local ambience loops with manual room binding and disable automatic transitions and remote assets.

COMMIT: `git add -A && git commit -m "[EP-026][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Soundscape Engine and Audio Studio, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-026-soundscape-engine-and-audio-studio.md`
- `.agent/node-contracts/EP-026.md`
- `.agent/milestone-files/EP-026-M5.txt`
- `.agent/expected-files/EP-026.txt`
- `.agent/expected-files/EP-026.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-026-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-026` at `tests/live-fire/LF-026-soundscape-degradation.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-026`
2. `sh scripts/record-evidence.sh EP-026 M5 "EP-026 M5: ok" -- sh scripts/node-verifiers/EP-026.sh M5`
3. `sh scripts/scope-audit.sh EP-026`

EXPECT:
- `EP-026 M5: ok`
- `scope audit EP-026: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-026 MILESTONE_PASS "M5 EP-026 M5: ok; evidence=.agent/state/evidence/EP-026/M5"`

FALLBACK: Support user-local ambience loops with manual room binding and disable automatic transitions and remote assets.

COMMIT: `git add -A && git commit -m "[EP-026][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-026` and require `node verify EP-026: ok`. Then run `sh scripts/expected-files-audit.sh EP-026`, `sh scripts/scope-audit.sh EP-026`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

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

- 2026-08-28: Lease acquired (known EP-018 ellipsis preflight FAIL, documented, outside fence, same state as EP-020-025).
- Source evidence WM-SRC-000176..000179: inherited TMedia audio API (playMedia/stopMedia/stopAllMediaPlayers/setVolume), owned UI boundary pattern, src/CMakeLists.txt integration point, asset manifest pattern.
- Discovered-path amendment for src/CMakeLists.txt (WM-SRC-000178); soundscape-build-integration contract test.
- Contract tests: soundscape-authority, soundscape-boundaries, soundscape-build-integration, soundscape-obligations — all ok.
- Node verifier scripts/node-verifiers/EP-026.sh (M1-M5 + verify).
- `node contract check EP-026: ok`; `EP-026 M1: ok`; `scope audit EP-026: ok changed=9`.

## 16. M2 Progress

- 2026-08-28: wire-soundscape crate (wirecore/crates/wire-soundscape) — 9 binding classes (room/area/combat/boss/weather/death/victory/ambience/user-authored), profile-scoped volume+disable, independent per-binding volume/enable, bounded+coalescing queue (MAX_AUDIO_QUEUE=64), bounded+cancelable transitions (MAX_TRANSITION_MS=5000), provenance gate (protected/unlicensed/remote-unsigned rejected, user-local fallback), emergency stop, audio-failure degrade preserving text (no text path), can_send_command=false. 21/21 deterministic tests.
- Audio schemas schemas/wiremudder/audio/ (binding/asset-pack/soundscape-state/studio-config/transition v1).
- Original CC0 procedural audio manifest assets/wiremudder/audio/manifest.json + README (SPEC-016-R01/R09).
- M2 unit test scripts (audio-schemas, wire-soundscape). `EP-026 M2: ok`; `scope audit EP-026: ok changed=23`.

## 17. M3 Progress

- 2026-08-28: Soundscape UI boundary src/wiremudder/ui/soundscape/soundscape_boundary.{h,cpp} (passive Qt6 model-side pane, states Loading/Ready/Disabled/Denied/Degraded/Canceled/Unavailable/Error, bindings with independent volume/disable, profile-scoped studio controls, mode, provenance display, transition request flags, failed state). Wired into src/CMakeLists.txt mudlet_SRCS + UI headers (discovered amendment WM-SRC-000178). Compiles clean vs real Qt6 (/opt/qt/6.8.2/gcc_64) with -Wall -Wextra zero warnings.
- Rust e2e example e2e_soundscape.rs proves all 6 acceptance obligations with real output lines.
- Integration test soundscape-boundary-qt6 (compile proof + passive invariants); e2e test soundscape-flow (6 obligation greps).
- Design docs docs/wiremudder/soundscape/design/architecture.md (data scope, privacy, authority, audit, health, restart, fallback, rollback).
- `EP-026 M3: ok`; `scope audit EP-026: ok changed=31`.

## 18. M4 Progress

- 2026-08-28: failure_matrix (8/8 proofs), security_matrix (5/5 proofs), perf_fixture (6 measured paths).
- Real finding: tick() did not promote the queued job to current loop; the duplicate-replay failure proof exposed it. Fixed tick() to promote front-of-queue when no transition in flight and nothing playing; coalescing test rewritten to queue Room/Area/Room and assert coalesce=1 + promotion. 21/21 still pass.
- Perf (release, real hardware): request-play 3.04us, tick-coalesce 14.34us, transition-start 3.32us, studio-control 0.27us, asset-provenance 0.55us, emergency-stop 2.97us. worst 14.34us vs P3 5000us budget; e-stop 2.97us vs P0 10000us budget.
- Operations runbook docs/wiremudder/soundscape/operations/runbook.md (health, readiness, disable, recovery, backup/restore, upgrade, rollback).
- `EP-026 M4: ok`; `scope audit EP-026: ok changed=39`.
