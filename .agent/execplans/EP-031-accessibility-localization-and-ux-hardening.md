NODE-META-BEGIN
ID: EP-031
DEPS: EP-012,EP-024,EP-025
MAX_ATTEMPTS_PER_MILESTONE: 6
VERIFY: sh scripts/node-verify.sh EP-031
VERIFY_SENTINEL: node verify EP-031: ok
GREEN_TAG: green/EP-031
NODE-META-END

# 1. Purpose and Big Picture

Complete keyboard, focus, screen-reader, non-color state, reduced-motion, large-text, subtitles, spoken feedback, raw-text fallback, translation, and usability testing across all enabled surfaces.

# 2. Scope

- Implement every obligation in `.agent/node-contracts/EP-031.md`.
- Own features: cross-cutting node.
- Own requirements: WM-SPEC-007-R10.
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

WireMudder preserves the pinned Mudlet foundation and adds isolated WireCore services. This node depends on EP-012, EP-024, EP-025. It must not assume later capabilities exist. P0 manual gameplay remains independent from optional systems.

# 5. Files to Read First

- `AGENTS.md`
- `COMMANDS.md`
- `.agent/GRAPH.md`
- `.agent/LOOPS.md`
- `ARCHITECTURE.md`
- `PERFORMANCE_CONSTITUTION.md`
- `WIREMUDDER_SECURITY.md`
- `TESTING.md`
- `.agent/node-contracts/EP-031.md`
- `.agent/expected-files/EP-031.txt`
- `.agent/expected-files/EP-031.discovered.txt`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

# 6. Expected Changed Files

The static fence is `.agent/expected-files/EP-031.txt`. The milestone fence is `.agent/milestone-files/EP-031-Mk.txt`. An inherited path is legal only after `.agent/expected-files/EP-031.discovered.txt` contains source evidence and the exact path.

- `.agent/execplans/EP-031-accessibility-localization-and-ux-hardening.md`
- `.agent/node-contracts/EP-031.md`
- `.agent/expected-files/EP-031.txt`
- `.agent/expected-files/EP-031.discovered.txt`
- `.agent/milestone-files/EP-031-M1.txt`
- `.agent/milestone-files/EP-031-M2.txt`
- `.agent/milestone-files/EP-031-M3.txt`
- `.agent/milestone-files/EP-031-M4.txt`
- `.agent/milestone-files/EP-031-M5.txt`
- `.agent/state/LEDGER.md`
- `.agent/state/source-evidence.jsonl`
- `.agent/state/source-evidence/`
- `.agent/state/COMMANDS.lock.tsv`
- `.agent/state/evidence/EP-031/`
- `scripts/node-verifiers/EP-031.sh`
- `tests/live-fire/LF-031-accessibility-keyboard-screenreader.sh`
- `tests/wiremudder/ep031/`
- `docs/wiremudder/accessibility/`
- `src/wiremudder/accessibility/`
- `tests/wiremudder/accessibility/`
- `translations/wiremudder/`

# 7. Interfaces and Contracts

- Node contract: `.agent/node-contracts/EP-031.md`.
- Accepted specifications: SPEC-007, SPEC-015, SPEC-016, SPEC-018, SPEC-027.
- Live-fire: `LF-031` `accessibility-keyboard-screenreader`.
- Public names and events come from `.agent/vocabulary/CANONICAL_TERMS.tsv` and `schemas/wiremudder/`.
- Errors follow SPEC-025; performance follows SPEC-004; security follows SPEC-022.

# 8. Milestones

### M1: Evidence, contracts, and exact path lock

GOAL: Lock the evidence, interfaces, exact inherited integration paths, node verifier, and tests before product implementation for Accessibility, Localization, and UX Hardening.

READ:
- `.agent/execplans/EP-031-accessibility-localization-and-ux-hardening.md`
- `.agent/node-contracts/EP-031.md`
- `.agent/milestone-files/EP-031-M1.txt`
- `.agent/expected-files/EP-031.txt`
- `.agent/expected-files/EP-031.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-031-M1.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Verify every inherited path, symbol, command, format, provider, and dependency needed by this node and append source evidence.
2. Review owned features: cross-cutting node.
3. Review owned requirements: WM-SPEC-007-R10.
4. Create the node verifier with subcommands M1 through M5 and verify; each subcommand must run real checks and print only its exact sentinel on success.
5. Add contract tests that fail for an absent or invalid boundary.
6. Add exact inherited paths to the discovered amendment before any inherited-source edit.
7. Record architecture, privacy, security, performance, compatibility, dependency, and rollback decisions.
8. Do not implement later-milestone product behavior in M1.

RUN:
1. `sh scripts/node-contract-check.sh EP-031`
2. `sh scripts/record-evidence.sh EP-031 M1 "EP-031 M1: ok" -- sh scripts/node-verifiers/EP-031.sh M1`
3. `sh scripts/scope-audit.sh EP-031`

EXPECT:
- `EP-031 M1: ok`
- `scope audit EP-031: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-031 MILESTONE_PASS "M1 EP-031 M1: ok; evidence=.agent/state/evidence/EP-031/M1"`

FALLBACK: Disable nonessential visual and voice surfaces that cannot meet accessibility requirements while preserving raw text operation.

COMMIT: `git add -A && git commit -m "[EP-031][M1] evidence contracts and exact path lock"`

### M2: Core behavior and deterministic invariants

GOAL: Implement the smallest real core behavior that satisfies the node contract for Accessibility, Localization, and UX Hardening inside namespaced boundaries.

READ:
- `.agent/execplans/EP-031-accessibility-localization-and-ux-hardening.md`
- `.agent/node-contracts/EP-031.md`
- `.agent/milestone-files/EP-031-M2.txt`
- `.agent/expected-files/EP-031.txt`
- `.agent/expected-files/EP-031.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-031-M2.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement only the interfaces and invariants declared by accepted specifications and the node contract.
2. Keep provider-specific, UI-specific, and inherited-source details behind adapters.
3. Add deterministic unit and contract tests for every core rule, denial, boundary, and state transition.
4. Use bounded resources, explicit cancellation, typed errors, and stable schema versions.
5. No mock, stub, sample success, or production test mode is allowed.
6. Run formatter and narrow tests before the milestone verifier.

RUN:
1. `sh scripts/node-contract-check.sh EP-031`
2. `sh scripts/record-evidence.sh EP-031 M2 "EP-031 M2: ok" -- sh scripts/node-verifiers/EP-031.sh M2`
3. `sh scripts/scope-audit.sh EP-031`

EXPECT:
- `EP-031 M2: ok`
- `scope audit EP-031: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-031 MILESTONE_PASS "M2 EP-031 M2: ok; evidence=.agent/state/evidence/EP-031/M2"`

FALLBACK: Disable nonessential visual and voice surfaces that cannot meet accessibility requirements while preserving raw text operation.

COMMIT: `git add -A && git commit -m "[EP-031][M2] core behavior and deterministic invariants"`

### M3: Real integration and user-visible flow

GOAL: Integrate Accessibility, Localization, and UX Hardening with the actual Mudlet-derived runtime, WireCore boundary, persistence, UI or headless surface, and controlled dependencies as applicable.

READ:
- `.agent/execplans/EP-031-accessibility-localization-and-ux-hardening.md`
- `.agent/node-contracts/EP-031.md`
- `.agent/milestone-files/EP-031-M3.txt`
- `.agent/expected-files/EP-031.txt`
- `.agent/expected-files/EP-031.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-031-M3.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise the real bridge, process, database, parser, provider, package, UI, headless, or platform boundary owned by this node.
2. Add integration and E2E tests with loading, ready, disabled, denied, degraded, canceled, unavailable, and error states.
3. Prove data scope, privacy disclosure, action authority, audit, health, and restart behavior.
4. Prove that optional failure preserves manual text gameplay.
5. Update design documentation with exact commands, observed behavior, and rollback.
6. Do not claim an external adapter or platform certified until M5 live-fire.

RUN:
1. `sh scripts/node-contract-check.sh EP-031`
2. `sh scripts/record-evidence.sh EP-031 M3 "EP-031 M3: ok" -- sh scripts/node-verifiers/EP-031.sh M3`
3. `sh scripts/scope-audit.sh EP-031`

EXPECT:
- `EP-031 M3: ok`
- `scope audit EP-031: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-031 MILESTONE_PASS "M3 EP-031 M3: ok; evidence=.agent/state/evidence/EP-031/M3"`

FALLBACK: Disable nonessential visual and voice surfaces that cannot meet accessibility requirements while preserving raw text operation.

COMMIT: `git add -A && git commit -m "[EP-031][M3] real integration and user visible flow"`

### M4: Forced failures, abuse cases, performance, and operations

GOAL: Break Accessibility, Localization, and UX Hardening deliberately and prove fail-closed, bounded, observable, recoverable behavior without a P0 or P1 regression.

READ:
- `.agent/execplans/EP-031-accessibility-localization-and-ux-hardening.md`
- `.agent/node-contracts/EP-031.md`
- `.agent/milestone-files/EP-031-M4.txt`
- `.agent/expected-files/EP-031.txt`
- `.agent/expected-files/EP-031.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-031-M4.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Exercise dependency unavailable, timeout, cancellation, malformed input, duplicate request, denied policy, resource exhaustion, and partial effect where applicable.
2. Use real controlled failure mechanisms rather than mocking the component being proven.
3. Assert typed errors, redacted logs, metrics, audit, cleanup, compensation, quarantine, retry bounds, and preserved gameplay.
4. Run threat, prompt injection, secrets, permission, supply-chain, migration, and data-integrity tests applicable to this node.
5. Run performance fixture and record hardware, workload, distributions, thresholds, and raw evidence.
6. Complete health, readiness, disable, recovery, backup, restore, upgrade, and rollback instructions applicable to this node.

RUN:
1. `sh scripts/node-contract-check.sh EP-031`
2. `sh scripts/record-evidence.sh EP-031 M4 "EP-031 M4: ok" -- sh scripts/node-verifiers/EP-031.sh M4`
3. `sh scripts/scope-audit.sh EP-031`

EXPECT:
- `EP-031 M4: ok`
- `scope audit EP-031: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-031 MILESTONE_PASS "M4 EP-031 M4: ok; evidence=.agent/state/evidence/EP-031/M4"`

FALLBACK: Disable nonessential visual and voice surfaces that cannot meet accessibility requirements while preserving raw text operation.

COMMIT: `git add -A && git commit -m "[EP-031][M4] forced failures abuse cases performance and operations"`

### M5: Live-fire, evidence closure, and green tag readiness

GOAL: Run the real user outcome for Accessibility, Localization, and UX Hardening, close every owned feature and requirement with evidence, and make the node eligible for DONE.

READ:
- `.agent/execplans/EP-031-accessibility-localization-and-ux-hardening.md`
- `.agent/node-contracts/EP-031.md`
- `.agent/milestone-files/EP-031-M5.txt`
- `.agent/expected-files/EP-031.txt`
- `.agent/expected-files/EP-031.discovered.txt`
- `.agent/state/LEDGER.md`
- `.agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md`
- `.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md`
- `.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md`
- `.agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md`
- `.agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md`

CHANGE: exact paths in `.agent/milestone-files/EP-031-M5.txt`; inherited paths additionally require the discovered amendment.

CONTENT:
1. Implement and run `LF-031` at `tests/live-fire/LF-031-accessibility-keyboard-screenreader.sh` against real controlled dependencies.
2. Run M1 through M5 verifier subcommands, full node verify, expected-file audit, scope audit, feature coverage, spec trace, and relevant broad repository gates.
3. Confirm every owned feature is implemented, certified, disabled, or blocked exactly as allowed by its release profile and no claim exceeds evidence.
4. Fill Progress, Surprises and Discoveries, Decision Log, and Outcomes with actual commands, exit codes, sentinels, hashes, and evidence paths.
5. Append MILESTONE_PASS only after observed output.
6. Do not append NODE_DONE or create a green tag until `scripts/node-verify.sh` performs all completion checks.

RUN:
1. `sh scripts/node-contract-check.sh EP-031`
2. `sh scripts/record-evidence.sh EP-031 M5 "EP-031 M5: ok" -- sh scripts/node-verifiers/EP-031.sh M5`
3. `sh scripts/scope-audit.sh EP-031`

EXPECT:
- `EP-031 M5: ok`
- `scope audit EP-031: ok`

EVIDENCE: `sh scripts/ledger.sh append "${WIREMUDDER_AGENT_ID}" EP-031 MILESTONE_PASS "M5 EP-031 M5: ok; evidence=.agent/state/evidence/EP-031/M5"`

FALLBACK: Disable nonessential visual and voice surfaces that cannot meet accessibility requirements while preserving raw text operation.

COMMIT: `git add -A && git commit -m "[EP-031][M5] live fire evidence closure and green tag readiness"`

# 9. Validation and Acceptance

Run `sh scripts/node-verify.sh EP-031` and require `node verify EP-031: ok`. Then run `sh scripts/expected-files-audit.sh EP-031`, `sh scripts/scope-audit.sh EP-031`, feature coverage, spec trace, and the owning live-fire proof. Cite exact evidence paths for every acceptance obligation.

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

- 2026-08-28 (M1): EP-031 is a cross-cutting node with no direct feature rows; the only owned requirement is WM-SPEC-007-R10 (validation matrix row maps it to live-fire LF-031 at tests/wiremudder/ep031/requirements/wm-spec-007-r10). The remaining accessibility obligations (keyboard, focus, screen-reader, reduced-motion, subtitles) live in WM-SPEC-007-R05, owned by EP-009, and WM-SPEC-027-R07. EP-031's contract still obligates cross-cutting accessibility evidence and release coverage across all enabled surfaces.
- 2026-08-28 (M1): The inherited Mudlet translation convention is fully mechanical: master `translations/mudlet.ts` (19392 lines), locale catalogs `translations/translated/mudlet_*.ts` (24 locales), compiled `.qm` registered in `translations/translated/qm.qrc` under the `/lang` resource prefix, built by `Qt6LinguistTools 6.8.2 REQUIRED` with `lrelease -compress -qm` (translations/translated/CMakeLists.txt), wired through `add_subdirectory(translations/translated)` (CMakeLists.txt:271) and `configure_file`/`target_sources` of qm.qrc (src/CMakeLists.txt:29/697), and loaded at runtime by `QTranslator::load(userLocale, "mudlet", "_", ":/lang", ".qm")` (src/main.cpp:161). New strings must follow this convention (WM-SPEC-007-R10) and new catalogs under translations/wiremudder/ must mirror it.
- 2026-08-28 (M1): The inherited integration seam for the new accessibility boundary is `src/CMakeLists.txt`, where the owned help/soundscape/diagnostics/import panes already sit (help_boundary.cpp at line 229, soundscape at 227, import added by EP-030). The discovered amendment (WM-SRC-000230) authorizes adding the accessibility boundary beside them; the contract test accessibility-build-integration.sh locks the pattern.
- 2026-08-28 (M2): The system Qt6 at /opt/qt/6.8.2/gcc_64 is not on the default linker path; a linked harness needs `-Wl,-rpath,$QTDIR/lib` and `LD_LIBRARY_PATH` at runtime or it fails with `version 'Qt_6.8' not found` against the older distro libQt6Core. The boundary compile-only proof (like EP-030) did not need this; the executable harness does.
- 2026-08-28 (M3): The Qt .qm resource sentry magic is 0x3C 0xB8 (value 15544), not the network-order value I first asserted; the real lrelease output verified the correct bytes. This is now locked in translation-build.sh.
- 2026-08-28 (M4): The performance fixture measured the accessibility boundary hot path at avg 0.008 µs per state transition (100000 iterations, 800.9 µs total) against a 5 µs budget — a pure view-model with no per-line blocking work.

# 13. Decision Log

Append date, decision, evidence, alternatives, consequence, reversal, affected features and requirements, security, privacy, license, compatibility, performance, and upstream impact.

- 2026-08-28 (M1): Adopt the inherited Mudlet translation convention exactly for WM-SPEC-007-R10: master .ts under translations/, locale .ts under a translated/ mirror, qm.qrc /lang registration, lrelease -compress -qm, runtime QTranslator load with the catalog name and .qm suffix. Evidence: WM-SRC-000222..000227. Alternatives: a separate ICU/fluent pipeline rejected because the spec demands the existing Mudlet convention and the runtime loader would not pick up another format. Consequence: new catalogs must mirror the inherited layout; no new runtime load path needed. Reversal: revert the translations/wiremudder/ catalog additions and any CMake wiring. Affects WM-SPEC-007-R10; compatibility and performance neutral; upstream impact none.
- 2026-08-28 (M1): Integrate the accessibility boundary into src/CMakeLists.txt beside the established owned panes (help/soundscape/diagnostics/import), via the discovered-path amendment (WM-SRC-000230). Evidence: help_boundary.cpp at src/CMakeLists.txt:229. Alternatives: a separate static library or plugin build rejected because the inherited Mudlet build is a single CMake target and prior nodes established the in-target boundary pattern. Consequence: the boundary compiles with the real Qt6 toolchain and joins the runtime. Reversal: `git checkout -- src/CMakeLists.txt` plus removal of the boundary sources. Affects SPEC-007 surfaces; security/privacy neutral.
- 2026-08-28 (M2): Implement the accessibility boundary as a passive Qt model (AccessibilityPaneModel) exposing the R05 obligation flags (keyboard, focus, screen-reader, non-color, large-text, reduced-motion, subtitles, raw-text) and the R10 translation catalog convention (name, resource, suffix, locales, translator context), with the same SPEC-025 state set and passive invariants (no command, no settings mutation, no secrets, no egress, raw text always visible) as the established help/import boundaries. Evidence: accessibility_boundary.h/.cpp; unit harness asserts all invariants against real Qt6. Alternatives: a Rust crate rejected because this node owns a Qt UI-surface obligation and prior boundary precedent is C++ in the inherited build; a mutating a11y settings API rejected by the passive-observer rule. Consequence: deterministic model invariants, real Qt6 compile proof. Reversal: remove the boundary sources and unit tests. Affects SPEC-007/015/016/018/027; security/privacy neutral; performance negligible (pure view-model).
- 2026-08-28 (M3): Wire the accessibility boundary into the inherited src/CMakeLists.txt (mudlet_SRCS + UI headers) beside help/import exactly as the discovered amendment authorizes (WM-SRC-000230), and add integration/e2e coverage: real Qt6 zero-warning compile, lrelease-compiled .qm with QM magic verification, translator context for every string, and an e2e pane flow through all eight SPEC-025 states proving raw text always stays visible even under Denied/Degraded. Evidence: integration/accessibility-boundary-qt6.sh, integration/translation-build.sh, e2e/accessibility-pane-flow.sh. Alternatives: leaving the boundary unwired (fails the node contract's integration obligation) or a separate build target (rejected per M1 decision). Consequence: the boundary compiles with the real Qt6 toolchain and joins the runtime source list. Reversal: `git checkout -- src/CMakeLists.txt` and remove the boundary sources. Affects SPEC-007 surfaces; security/privacy neutral.
- 2026-08-28 (M4): Prove fail-closed and bounded behavior with real controlled harnesses: (1) failure matrix — all eight SPEC-025 failure states, hostile malformed profile attempting to hide raw text and spoof authority, idempotent duplicate updates, reset compensation; (2) security matrix — boundary contains no QNetworkAccessManager/QProcess/setenv/system/markup renderer/secret-like identifiers and the catalog has no scriptable content; (3) performance — 0.008 µs/op avg vs 5 µs budget; (4) operations runbook at docs/wiremudder/accessibility/operations/runbook.md. Evidence: failure/security/performance tests + runbook. Alternatives: mocking the boundary to force failures rejected by the real-controlled-failure rule. Consequence: fail-closed posture proven under every failure state. Reversal: remove the M4 test directories. Affects SPEC-007/015/016/018/027; security/privacy strengthened.

# 14. Outcomes and Retrospective

At completion record changed versus expected files, source evidence, commands, exit codes, observed sentinels, evidence hashes, feature and requirement disposition, provider and platform certification, assumptions changed, risks, rollback, green tag, and next scheduler output.

## EP-031 Outcomes (2026-08-28)

- Changed vs expected: all changes inside the static fence plus the one
  discovered-path amendment (`src/CMakeLists.txt`, WM-SRC-000230).
  Changed files per milestone: M1 9, M2 10, M3 8, M4 8, M5 5 (plus ledger).
- Source evidence: WM-SRC-000222..000230 recorded at M1 (translation
  convention, requirement anchor, boundary anchors).
- Commands and observed sentinels:
  - `sh scripts/node-verifiers/EP-031.sh M1` -> `EP-031 M1: ok`
  - M2 -> `EP-031 M2: ok`; M3 -> `EP-031 M3: ok`; M4 -> `EP-031 M4: ok`;
    M5 -> `EP-031 M5: ok`
  - `sh scripts/live-fire/LF-031-accessibility-keyboard-screenreader.sh`
    -> `LF-031: ok` (obligations 1..6 true)
  - `sh scripts/node-contract-check.sh EP-031` -> `node contract check EP-031: ok`
  - `sh scripts/scope-audit.sh EP-031` -> `scope audit EP-031: ok changed=31`
  - Expected-files audit passed inside M5 verifier.
- Feature disposition: EP-031 owns no feature rows (cross-cutting). The
  cross-cutting feature test proves the SPEC-027-R07 accessibility
  dimensions (keyboard, focus, semantics, non-color, reduced-motion,
  no-animation, subtitles, raw-text) are all exposed by the boundary.
- Requirement disposition: WM-SPEC-007-R10 owned and satisfied
  (catalog follows inherited Mudlet convention with translator context;
  real lrelease compile; boundary requires translator context).
- Provider/platform certification: no external provider; Qt6 (6.8.2)
  boundary compile certified with zero warnings; lrelease certified.
- Assumptions changed: none.
- Risks: none open; performance 0.008 us/op, far inside budget.
- Rollback: remove boundary sources/tests/docs, `git checkout --
  src/CMakeLists.txt`, remove translations/wiremudder.
- Green tag: `green/EP-031` (created after `node verify EP-031: ok`).
- Next scheduler output: per `scripts/graph-next.sh` after lease release.
