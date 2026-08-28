NODE-META-BEGIN
ID: EP-024
DEPS: EP-006,EP-008,EP-016,EP-023
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-024
VERIFY_SENTINEL: node verify EP-024: ok
GREEN_TAG: green/EP-024
NODE-META-END

# 1. Purpose and Big Picture

Implement push-to-talk voice, local-first STT/TTS, optional approved remote providers, visible mic state, voice macros through Action Proposals, agent voice styles, cancellation, subtitles, and load shedding.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-024.md`.
- Own features: WM-FEAT-0057, WM-FEAT-0058, WM-FEAT-0059, WM-FEAT-0060, WM-FEAT-0061, WM-FEAT-0062, WM-FEAT-0063, WM-FEAT-0064, WM-FEAT-0065, WM-FEAT-0066, WM-FEAT-0067, WM-FEAT-0068, plus 3 more rows in FEATURES.tsv.
- Own requirements: WM-SPEC-007-R02, WM-SPEC-010-R08, WM-SPEC-015-R07, WM-SPEC-015-R10.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-006, EP-008, EP-016, EP-023. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-024.md`
- `.agent/expected-files/EP-024.txt`
- `.agent/expected-files/EP-024.discovered.txt`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-024.txt`. The milestone fence is `.agent/milestone-files/EP-024-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-024.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-024-ambient-voice-companion-and-voice-macros.md`
- `.agent/node-contracts/EP-024.md`
- `.agent/expected-files/EP-024.txt`
- `.agent/expected-files/EP-024.discovered.txt`
- `.agent/milestone-files/EP-024-M1.txt`
- `.agent/milestone-files/EP-024-M2.txt`
- `.agent/milestone-files/EP-024-M3.txt`
- `.agent/milestone-files/EP-024-M4.txt`
- `.agent/milestone-files/EP-024-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-024/`
- `scripts/node-verifiers/EP-024.sh`
- `tests/live-fire/LF-024-voice-privacy-command.sh`
- `tests/wiremudder/ep024/`
- `docs/wiremudder/voice/`
- `wirecore/crates/wire-voice/`
- `src/wiremudder/ui/voice/`
- `schemas/wiremudder/voice/`
- `config/wiremudder/voice/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-024.md`.
- Accepted specifications: SPEC-009, SPEC-010, SPEC-015, SPEC-017, SPEC-022.
- Live-fire: `LF-024` `voice-privacy-command`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Ambient Voice Companion and Voice Macros.

READ:
- `.agent/execplans/EP-024-ambient-voice-companion-and-voice-macros.md`
- `.agent/node-contracts/EP-024.md`
- `.agent/milestone-files/EP-024-M1.txt`
- `.agent/expected-files/EP-024.txt`
- `.agent/expected-files/EP-024.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-024-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0057, WM-FEAT-0058, WM-FEAT-0059, WM-FEAT-0060, WM-FEAT-0061, WM-FEAT-0062, WM-FEAT-0063, WM-FEAT-0064, WM-FEAT-0065, WM-FEAT-0066, WM-FEAT-0067, WM-FEAT-0068, plus 3 more rows in FEATURES.tsv.
3. Review owned requirements: WM-SPEC-007-R02, WM-SPEC-010-R08, WM-SPEC-015-R07, WM-SPEC-015-R10.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-024`
2. `sh scripts/record-evidence.sh EP-024 M1 "EP-024 M1: ok" -- sh scripts/node-verifiers/EP-024.sh M1`
3. `sh scripts/scope-audit.sh EP-024`

EXPECT:
- `EP-024 M1: ok`
- `scope audit EP-024: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-024 MILESTONE_PASS "M1 EP-024 M1: ok; evidence=.agent/state/evidence/EP-024/M1"`

FALLBACK: Ship voice disabled or with one certified local push-to-talk provider; omit wake phrase and remote speech until separately certified.

COMMIT: `git add -A && git commit -m "[EP-024][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Ambient Voice Companion and Voice Macros inside namespaced boundaries.

READ:
- `.agent/execplans/EP-024-ambient-voice-companion-and-voice-macros.md`
- `.agent/node-contracts/EP-024.md`
- `.agent/milestone-files/EP-024-M2.txt`
- `.agent/expected-files/EP-024.txt`
- `.agent/expected-files/EP-024.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-024-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-024`
2. `sh scripts/record-evidence.sh EP-024 M2 "EP-024 M2: ok" -- sh scripts/node-verifiers/EP-024.sh M2`
3. `sh scripts/scope-audit.sh EP-024`

EXPECT:
- `EP-024 M2: ok`
- `scope audit EP-024: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-024 MILESTONE_PASS "M2 EP-024 M2: ok; evidence=.agent/state/evidence/EP-024/M2"`

FALLBACK: Ship voice disabled or with one certified local push-to-talk provider; omit wake phrase and remote speech until separately certified.

COMMIT: `git add -A && git commit -m "[EP-024][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Ambient Voice Companion and Voice Macros with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-024-ambient-voice-companion-and-voice-macros.md`
- `.agent/node-contracts/EP-024.md`
- `.agent/milestone-files/EP-024-M3.txt`
- `.agent/expected-files/EP-024.txt`
- `.agent/expected-files/EP-024.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-024-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-024`
2. `sh scripts/record-evidence.sh EP-024 M3 "EP-024 M3: ok" -- sh scripts/node-verifiers/EP-024.sh M3`
3. `sh scripts/scope-audit.sh EP-024`

EXPECT:
- `EP-024 M3: ok`
- `scope audit EP-024: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-024 MILESTONE_PASS "M3 EP-024 M3: ok; evidence=.agent/state/evidence/EP-024/M3"`

FALLBACK: Ship voice disabled or with one certified local push-to-talk provider; omit wake phrase and remote speech until separately certified.

COMMIT: `git add -A && git commit -m "[EP-024][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Ambient Voice Companion and Voice Macros deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-024-ambient-voice-companion-and-voice-macros.md`
- `.agent/node-contracts/EP-024.md`
- `.agent/milestone-files/EP-024-M4.txt`
- `.agent/expected-files/EP-024.txt`
- `.agent/expected-files/EP-024.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-024-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-024`
2. `sh scripts/record-evidence.sh EP-024 M4 "EP-024 M4: ok" -- sh scripts/node-verifiers/EP-024.sh M4`
3. `sh scripts/scope-audit.sh EP-024`

EXPECT:
- `EP-024 M4: ok`
- `scope audit EP-024: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-024 MILESTONE_PASS "M4 EP-024 M4: ok; evidence=.agent/state/evidence/EP-024/M4"`

FALLBACK: Ship voice disabled or with one certified local push-to-talk provider; omit wake phrase and remote speech until separately certified.

COMMIT: `git add -A && git commit -m "[EP-024][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Ambient Voice Companion and Voice Macros, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-024-ambient-voice-companion-and-voice-macros.md`
- `.agent/node-contracts/EP-024.md`
- `.agent/milestone-files/EP-024-M5.txt`
- `.agent/expected-files/EP-024.txt`
- `.agent/expected-files/EP-024.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md`
- `.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-017-multi-session-headless-and-supervisor.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-024-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-024` at `tests/live-fire/LF-024-voice-privacy-command.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-024`
2. `sh scripts/record-evidence.sh EP-024 M5 "EP-024 M5: ok" -- sh scripts/node-verifiers/EP-024.sh M5`
3. `sh scripts/scope-audit.sh EP-024`

EXPECT:
- `EP-024 M5: ok`
- `scope audit EP-024: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-024 MILESTONE_PASS "M5 EP-024 M5: ok; evidence=.agent/state/evidence/EP-024/M5"`

FALLBACK: Ship voice disabled or with one certified local push-to-talk provider; omit wake phrase and remote speech until separately certified.

COMMIT: `git add -A && git commit -m "[EP-024][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-024` and require `node verify EP-024: ok`. Then run `sh scripts/expected-files-audit.sh EP-024`, `sh scripts/scope-audit.sh EP-024`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

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

2026-08-28: The security matrix surfaced a real fail-closed gap: a voice
macro with risk tier `manual` was initially accepted when
`confirmation_required=false`. That is wrong for an automated source —
`manual` is the direct user-typed tier and must never be claimed by
voice/automation. Fixed `VoiceMacro::validate()` to reject `manual`
outright (WM-SPEC-009-R02 fail-closed); unit suite and security matrix
both re-verified.

2026-08-28: The failure matrix exposed a fixture bug: the queue-exhaustion
sample reused the same companion that had already queued the remote-speech
job from the consent sample, so the 64-slot cap was hit one job early.
Fixed by using a fresh companion for the queue-exhaustion sample so the
real cap is the only constraint (same class of self-limiting fixture issue
as EP-022/EP-023 M4).

2026-08-28: Real measured performance: all P3 voice paths stay well under
the 5 ms SPEC-004 budget (mean worst case ~27 µs across recognize,
enqueue, barge-in, snapshot, remote-policy, emergency-stop samples);
emergency stop measured ~24-27 µs, far under the 10 ms P0 target.

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

2026-08-28: M1 decisions recorded.
- Architecture: voice core lives in `wirecore/crates/wire-voice/` (namespaced new code); the desktop surface is a model-side Qt boundary in `src/wiremudder/ui/voice/` following the EP-020/EP-022 pane pattern; schemas under `schemas/wiremudder/voice/`; provider registry under `config/wiremudder/voice/`. Evidence: WM-SRC-000155..167.
- Privacy: microphone state always visible; voice transcripts redacted by default; remote speech requires consent, privacy policy, and redaction (SPEC-015-R04, SPEC-010-R08); Local Only Lockdown blocks remote speech. Evidence: WM-SRC-000159, WM-SRC-000162.
- Security: voice has no new authority; voice commands pass the same Action Proposal command-safety path as all automation (SPEC-009-R02); no voice bypass of command safety; prompt injection cannot override voice policy (SPEC-022-R04). Evidence: WM-SRC-000158, WM-SRC-000162, WM-SRC-000165.
- Performance: voice is P3; queues bounded and cancelable; may shed P3 work; no voice job synchronous with input; emergency stop under 10 ms. Evidence: WM-SRC-000161.
- Compatibility: voice integrates through the inherited `src/CMakeLists.txt` source list exactly beside prior owned panes; discovered-path amendment WM-SRC-000155 authorizes that single inherited edit; rollback is `git checkout -- src/CMakeLists.txt`.
- Dependency: remote voice providers stay certified=false until live-fire; no new dependency added; crate uses serde/serde_json only (same as wire-headless).
- Fallback: ship voice disabled or with one certified local push-to-talk provider; omit wake phrase and remote speech until separately certified.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

2026-08-28: EP-024 complete and released.
- Commands and sentinels: `sh scripts/node-verify.sh EP-024` -> `node verify EP-024: ok`; `LF-024 voice-privacy-command: ok` with 6/6 certification obligations true; M1-M5 verifier subcommands each print their exact sentinel.
- Source evidence: WM-SRC-000155..167 recorded before any inherited edit; single discovered-path amendment for `src/CMakeLists.txt` (WM-SRC-000155).
- Feature disposition: WM-FEAT-0057..0068, 0186, 0211, 0212 all implemented and certified via feature tests + LF-024.
- Requirement disposition: WM-SPEC-007-R02 (voice surface), WM-SPEC-010-R08 (private voice protected), WM-SPEC-015-R07 (licensed styles), WM-SPEC-015-R10 (degrade to text) all implemented with automated tests; WM-SPEC-015-R10 is live-fire class and covered by LF-024.
- Provider/platform certification: voice shipped disabled by default with local-first architecture (local provider path certified in-crate; remote providers stay certified=false until separately certified, matching the EP-024 fallback). Qt6 (/opt/qt/6.8.2/gcc_64) compile proof for the voice boundary.
- Risks: remote STT/TTS providers remain uncertified by design; wake phrase and remote speech are omitted until separately certified.
- Rollback: `git checkout -- src/CMakeLists.txt` reverts the single inherited edit; remove the four authorized boundaries to remove the node.
- Green tag: `green/EP-024` created after full node verify.
- Scheduler: next output recorded in the ledger.
