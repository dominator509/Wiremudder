NODE-META-BEGIN
ID: EP-025
DEPS: EP-012,EP-015,EP-021
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-025
VERIFY_SENTINEL: node verify EP-025: ok
GREEN_TAG: green/EP-025
NODE-META-END

# 1. Purpose and Big Picture

Implement original retro room backdrops, diorama or tile/sprite surfaces, visual emit extraction, overlays, clickable exits, provenance, confidence, caching, frame budgets, and static/text fallback.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-025.md`.
- Own features: WM-FEAT-0069, WM-FEAT-0070, WM-FEAT-0071, WM-FEAT-0072, WM-FEAT-0073, WM-FEAT-0074, WM-FEAT-0077, WM-FEAT-0185, WM-FEAT-0207, WM-FEAT-0208, WM-FEAT-0209, WM-FEAT-0210.
- Own requirements: WM-SPEC-004-R04, WM-SPEC-004-R07, WM-SPEC-016-R01, WM-SPEC-016-R03, WM-SPEC-016-R05, WM-SPEC-016-R06, WM-SPEC-016-R09, WM-SPEC-016-R10.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-012, EP-015, EP-021. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-025.md`
- `.agent/expected-files/EP-025.txt`
- `.agent/expected-files/EP-025.discovered.txt`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-025.txt`. The milestone fence is `.agent/milestone-files/EP-025-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-025.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-025-retro-renderer-diorama-and-visual-emits.md`
- `.agent/node-contracts/EP-025.md`
- `.agent/expected-files/EP-025.txt`
- `.agent/expected-files/EP-025.discovered.txt`
- `.agent/milestone-files/EP-025-M1.txt`
- `.agent/milestone-files/EP-025-M2.txt`
- `.agent/milestone-files/EP-025-M3.txt`
- `.agent/milestone-files/EP-025-M4.txt`
- `.agent/milestone-files/EP-025-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-025/`
- `scripts/node-verifiers/EP-025.sh`
- `tests/live-fire/LF-025-renderer-degradation.sh`
- `tests/wiremudder/ep025/`
- `docs/wiremudder/renderer/`
- `src/wiremudder/ui/renderer/`
- `wirecore/crates/wire-renderer/`
- `schemas/wiremudder/renderer/`
- `assets/wiremudder/renderer/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-025.md`.
- Accepted specifications: SPEC-004, SPEC-007, SPEC-012, SPEC-016, SPEC-022.
- Live-fire: `LF-025` `renderer-degradation`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Retro Renderer, Diorama, and Visual Emits.

READ:
- `.agent/execplans/EP-025-retro-renderer-diorama-and-visual-emits.md`
- `.agent/node-contracts/EP-025.md`
- `.agent/milestone-files/EP-025-M1.txt`
- `.agent/expected-files/EP-025.txt`
- `.agent/expected-files/EP-025.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-025-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: WM-FEAT-0069, WM-FEAT-0070, WM-FEAT-0071, WM-FEAT-0072, WM-FEAT-0073, WM-FEAT-0074, WM-FEAT-0077, WM-FEAT-0185, WM-FEAT-0207, WM-FEAT-0208, WM-FEAT-0209, WM-FEAT-0210.
3. Review owned requirements: WM-SPEC-004-R04, WM-SPEC-004-R07, WM-SPEC-016-R01, WM-SPEC-016-R03, WM-SPEC-016-R05, WM-SPEC-016-R06, WM-SPEC-016-R09, WM-SPEC-016-R10.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-025`
2. `sh scripts/record-evidence.sh EP-025 M1 "EP-025 M1: ok" -- sh scripts/node-verifiers/EP-025.sh M1`
3. `sh scripts/scope-audit.sh EP-025`

EXPECT:
- `EP-025 M1: ok`
- `scope audit EP-025: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-025 MILESTONE_PASS "M1 EP-025 M1: ok; evidence=.agent/state/evidence/EP-025/M1"`

FALLBACK: Provide static user-selected room backdrops and disable animation, inferred emits, and external asset generation.

COMMIT: `git add -A && git commit -m "[EP-025][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Retro Renderer, Diorama, and Visual Emits inside namespaced boundaries.

READ:
- `.agent/execplans/EP-025-retro-renderer-diorama-and-visual-emits.md`
- `.agent/node-contracts/EP-025.md`
- `.agent/milestone-files/EP-025-M2.txt`
- `.agent/expected-files/EP-025.txt`
- `.agent/expected-files/EP-025.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-025-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-025`
2. `sh scripts/record-evidence.sh EP-025 M2 "EP-025 M2: ok" -- sh scripts/node-verifiers/EP-025.sh M2`
3. `sh scripts/scope-audit.sh EP-025`

EXPECT:
- `EP-025 M2: ok`
- `scope audit EP-025: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-025 MILESTONE_PASS "M2 EP-025 M2: ok; evidence=.agent/state/evidence/EP-025/M2"`

FALLBACK: Provide static user-selected room backdrops and disable animation, inferred emits, and external asset generation.

COMMIT: `git add -A && git commit -m "[EP-025][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Retro Renderer, Diorama, and Visual Emits with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-025-retro-renderer-diorama-and-visual-emits.md`
- `.agent/node-contracts/EP-025.md`
- `.agent/milestone-files/EP-025-M3.txt`
- `.agent/expected-files/EP-025.txt`
- `.agent/expected-files/EP-025.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-025-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-025`
2. `sh scripts/record-evidence.sh EP-025 M3 "EP-025 M3: ok" -- sh scripts/node-verifiers/EP-025.sh M3`
3. `sh scripts/scope-audit.sh EP-025`

EXPECT:
- `EP-025 M3: ok`
- `scope audit EP-025: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-025 MILESTONE_PASS "M3 EP-025 M3: ok; evidence=.agent/state/evidence/EP-025/M3"`

FALLBACK: Provide static user-selected room backdrops and disable animation, inferred emits, and external asset generation.

COMMIT: `git add -A && git commit -m "[EP-025][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Retro Renderer, Diorama, and Visual Emits deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-025-retro-renderer-diorama-and-visual-emits.md`
- `.agent/node-contracts/EP-025.md`
- `.agent/milestone-files/EP-025-M4.txt`
- `.agent/expected-files/EP-025.txt`
- `.agent/expected-files/EP-025.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-025-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-025`
2. `sh scripts/record-evidence.sh EP-025 M4 "EP-025 M4: ok" -- sh scripts/node-verifiers/EP-025.sh M4`
3. `sh scripts/scope-audit.sh EP-025`

EXPECT:
- `EP-025 M4: ok`
- `scope audit EP-025: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-025 MILESTONE_PASS "M4 EP-025 M4: ok; evidence=.agent/state/evidence/EP-025/M4"`

FALLBACK: Provide static user-selected room backdrops and disable animation, inferred emits, and external asset generation.

COMMIT: `git add -A && git commit -m "[EP-025][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Retro Renderer, Diorama, and Visual Emits, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-025-retro-renderer-diorama-and-visual-emits.md`
- `.agent/node-contracts/EP-025.md`
- `.agent/milestone-files/EP-025-M5.txt`
- `.agent/expected-files/EP-025.txt`
- `.agent/expected-files/EP-025.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-004-performance-constitution-and-degradation.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md`

CHANGE: exact paths in `.agent/milestone-files/EP-025-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-025` at `tests/live-fire/LF-025-renderer-degradation.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-025`
2. `sh scripts/record-evidence.sh EP-025 M5 "EP-025 M5: ok" -- sh scripts/node-verifiers/EP-025.sh M5`
3. `sh scripts/scope-audit.sh EP-025`

EXPECT:
- `EP-025 M5: ok`
- `scope audit EP-025: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-025 MILESTONE_PASS "M5 EP-025 M5: ok; evidence=.agent/state/evidence/EP-025/M5"`

FALLBACK: Provide static user-selected room backdrops and disable animation, inferred emits, and external asset generation.

COMMIT: `git add -A && git commit -m "[EP-025][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-025` and require `node verify EP-025: ok`. Then run `sh scripts/expected-files-audit.sh EP-025`, `sh scripts/scope-audit.sh EP-025`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

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

2026-08-28: The failure matrix surfaced a real observability gap:
`track_provenance` recorded provenance but did not write the audit
trail, so an audit replay could not reconstruct provenance events.
Fixed by appending a `provenance <origin>` audit entry; the failure
matrix's preserved-data-integrity proof now asserts the exact audit
count and passes.

2026-08-28: The renderer M4 fixture proved the frame-budget path with a
real 128-emit queue: a full 5 ms frame drains the whole batch at ~70 us
measured, far under the 4-6 ms SPEC-016 frame budget; worst-case P3 path
stays ~70 us and emergency stop ~66 us (P0 budget 10 ms).

2026-08-28: Asset provenance is enforced at the deterministic gate:
`protected:` provenance and `unlicensed` license are rejected outright;
unsigned non-local packs are rejected (SPEC-016-R09), so only
signed/licensed or user-local packs can supply renderer content.

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

2026-08-28: M1 decisions recorded.
- Architecture: renderer core lives in `wirecore/crates/wire-renderer/` (namespaced new code); the desktop surface is a model-side Qt boundary in `src/wiremudder/ui/renderer/` following the EP-020/EP-022/EP-024 pane pattern; schemas under `schemas/wiremudder/renderer/`; original assets under `assets/wiremudder/renderer/`. Evidence: WM-SRC-000168..175.
- Licensing: assets are original or properly licensed; no protected Nintendo/Zelda/Mario or third-party trade dress (SPEC-016-R01); asset packs carry license, provenance, hash, signature or user-local source, and permissions (SPEC-016-R09).
- Security: asset metadata is validated; renderer interactions cannot grant scopes or send commands (WIREMUDDER_SECURITY.md lines 21/32); no new authority, secret access, or remote egress (contract).
- Performance: renderer is P3 (SPEC-004-R04); frame-budgeted queues drop/coalesce noncritical emits and freeze to static before terminal degrades (SPEC-016-R06); 4-6 ms frame budget target (SPEC-016 Performance).
- Compatibility: renderer integrates through the inherited `src/CMakeLists.txt` source list exactly beside prior owned panes; discovered-path amendment WM-SRC-000168 authorizes that single inherited edit; rollback is `git checkout -- src/CMakeLists.txt`.
- Dependency: crate uses serde/serde_json only; no new dependency; raw text remains visible and authoritative (SPEC-016-R04).
- Fallback: static user-selected room backdrops; disable animation, inferred emits, and external asset generation.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

2026-08-28: EP-025 complete and released.
- Commands and sentinels: `sh scripts/node-verify.sh EP-025` -> `node verify EP-025: ok`; `LF-025 renderer-degradation: ok` with 6/6 certification obligations true; M1-M5 verifier subcommands each print their exact sentinel.
- Source evidence: WM-SRC-000168..175 recorded before any inherited edit; single discovered-path amendment for `src/CMakeLists.txt` (WM-SRC-000168).
- Feature disposition: WM-FEAT-0069..0074, 0077, 0185, 0207..0210 all implemented and certified via feature tests + LF-025.
- Requirement disposition: WM-SPEC-004-R04/R07, WM-SPEC-016-R01/R03/R05/R06/R09/R10 all implemented with automated tests; WM-SPEC-016-R10 is live-fire class and covered by LF-025.
- Asset certification: original procedural assets (CC0, provenance `original:wiremudder:procedural`) under `assets/wiremudder/renderer/`; no protected third-party assets; pack provenance gate enforced in-crate.
- Platform certification: Qt6 (/opt/qt/6.8.2/gcc_64) compile proof for the renderer boundary; renderer shipped in static mode by default with text-only fallback (EP-025 fallback honored).
- Risks: animation and external asset generation remain disabled by default; inferred emits require confidence display.
- Rollback: `git checkout -- src/CMakeLists.txt` reverts the single inherited edit; remove the four authorized boundaries to remove the node.
- Green tag: `green/EP-025` created after full node verify.
- Scheduler: next output recorded in the ledger.
