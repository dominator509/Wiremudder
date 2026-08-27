# WireMudder Roadmap

Do not implement from this file. Implementation happens only through the graph: run `sh scripts/graph-next.sh`.

## Build Arc

The graph first proves and preserves the inherited Mudlet baseline, then builds compatibility and contracts, then the minimal bridge and safety foundation, then classic parity and local storage, then AI and assistance, then immersion and developer tooling, then imports, accessibility, performance, security, updates, installers, platform certification, documentation, release-candidate hardening, and the ship gate.

## EP-000: Upstream Discovery and Evidence Lock

Inspect the actual Mudlet-derived repository, verify the pinned upstream commit and release evidence, inventory source, build, tests, dependencies, licenses, packages, agent instructions, and platform commands, and create a machine-readable source-evidence baseline before any product edit.

- Dependencies: none.
- Specifications: SPEC-000, SPEC-001, SPEC-005, SPEC-027.
- ExecPlan: `.agent/execplans/EP-000-upstream-discovery-and-evidence-lock.md`.
- Live-fire proof: `LF-000` `upstream-baseline-discovery`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-000`.

## EP-001: Graphlock Overlay and Inherited Baseline

Install the Graphlock control plane into the Mudlet-derived repository, preserve upstream instructions, build the inherited client without functional WireMudder changes, and prove the reference baseline user flow.

- Dependencies: EP-000.
- Specifications: SPEC-000, SPEC-001, SPEC-002, SPEC-005.
- ExecPlan: `.agent/execplans/EP-001-graphlock-overlay-and-inherited-baseline.md`.
- Live-fire proof: `LF-001` `unchanged-inherited-baseline`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-001`.

## EP-002: Fork Governance, Upstream Sync, and Branding

Establish origin/upstream remotes, branch and sync policy, patch classifications, attribution, GPL/source obligations, minimal branding boundaries, contribution workflow, and a reversible upstream synchronization drill.

- Dependencies: EP-001.
- Specifications: SPEC-001, SPEC-020, SPEC-022, SPEC-028.
- ExecPlan: `.agent/execplans/EP-002-fork-governance-upstream-sync-and-branding.md`.
- Live-fire proof: `LF-002` `upstream-sync-drill`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-002`.

## EP-003: Compatibility Oracle, Protocol Museum, and Replay

Build the independent reference harness, controlled fake MUD servers, trace normalization, sanitized profile/package/map corpus, differential comparison, replay format, and evidence rules that prevent implementation and tests from sharing the same hallucination.

- Dependencies: EP-002.
- Specifications: SPEC-003, SPEC-005, SPEC-006, SPEC-019, SPEC-021, SPEC-027.
- ExecPlan: `.agent/execplans/EP-003-compatibility-oracle-protocol-museum-and-replay.md`.
- Live-fire proof: `LF-003` `compatibility-oracle-roundtrip`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-003`.

## EP-004: Canonical Vocabulary, Schemas, and Traceability

Create the canonical event, capability, error, privacy, profile, command, memory, telemetry, package, update, voice, renderer, and headless schemas plus generated-binding and requirement traceability gates.

- Dependencies: EP-003.
- Specifications: SPEC-003, SPEC-023, SPEC-024, SPEC-025.
- ExecPlan: `.agent/execplans/EP-004-canonical-vocabulary-schemas-and-traceability.md`.
- Live-fire proof: `LF-004` `schema-contract-roundtrip`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-004`.

## EP-005: Native Bridge, WireCore Boundary, and Supervision

Implement the minimal C++/Qt bridge, Rust WireCore process foundation, local peer authentication, version handshake, bounded queues, snapshots, cancellation, health, restart, and crash isolation without moving classic gameplay out of Mudlet.

- Dependencies: EP-004.
- Specifications: SPEC-002, SPEC-003, SPEC-004, SPEC-024, SPEC-025, SPEC-026.
- ExecPlan: `.agent/execplans/EP-005-native-bridge-wirecore-boundary-and-supervision.md`.
- Live-fire proof: `LF-005` `sidecar-crash-isolation`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-005`.

## EP-006: Privacy, Consent, Secrets, and Local Only

Implement Privacy Firewall, consent receipts, redaction, Secrets Vault, sensitivity policy, Local Only Lockdown, immutable audit events, and denial-first egress controls.

- Dependencies: EP-005.
- Specifications: SPEC-010, SPEC-022, SPEC-023, SPEC-025.
- ExecPlan: `.agent/execplans/EP-006-privacy-consent-secrets-and-local-only.md`.
- Live-fire proof: `LF-006` `local-only-lockdown`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-006`.

## EP-007: Character Profiles and Network Routing

Implement Character Memory Profiles, per-character defaults, legitimate user-controlled routing profile records, connection-time validation, no-silent-fallback behavior, latency display, and routing audit.

- Dependencies: EP-006.
- Specifications: SPEC-006, SPEC-010, SPEC-017, SPEC-023.
- ExecPlan: `.agent/execplans/EP-007-character-profiles-and-network-routing.md`.
- Live-fire proof: `LF-007` `profile-routing-persistence`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-007`.

## EP-008: Command Safety, Emergency Stop, and Human-Tempo

Implement the deterministic Action Proposal gateway, command database, risk tiers, confirmations, visible queue, cooldowns, Human-Tempo safety, complete audit, and global emergency stop for every non-manual source.

- Dependencies: EP-007.
- Specifications: SPEC-004, SPEC-009, SPEC-010, SPEC-022.
- ExecPlan: `.agent/execplans/EP-008-command-safety-emergency-stop-and-human-tempo.md`.
- Live-fire proof: `LF-008` `emergency-stop-command-gate`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-008`.

## EP-009: Inherited Classic Client Parity

Audit and fixture the complete inherited terminal, profile, automation, layout, package, Lua, mapper, and classic-client surface and add only minimal WireMudder integration hooks where required.

- Dependencies: EP-008.
- Specifications: SPEC-004, SPEC-005, SPEC-007, SPEC-008, SPEC-027.
- ExecPlan: `.agent/execplans/EP-009-inherited-classic-client-parity.md`.
- Live-fire proof: `LF-009` `classic-client-regression`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-009`.

## EP-010: Scripting, Plugins, Packages, and Permissions

Preserve Lua scripting while implementing budgets, diagnostics, package manifests, permission firewall, signed or user-local provenance, package browser contracts, and safe update behavior.

- Dependencies: EP-009.
- Specifications: SPEC-005, SPEC-008, SPEC-020, SPEC-022.
- ExecPlan: `.agent/execplans/EP-010-scripting-plugins-packages-and-permissions.md`.
- Live-fire proof: `LF-010` `package-script-sandbox`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-010`.

## EP-011: Protocols, Network, and Capability Detection

Validate inherited Telnet and protocol behavior, harden parsers, expand protocol events, implement world capability detection, and close research decisions for MCP, Pueblo, and Simutronics/GSL.

- Dependencies: EP-009.
- Specifications: SPEC-005, SPEC-006, SPEC-018, SPEC-022, SPEC-027.
- ExecPlan: `.agent/execplans/EP-011-protocols-network-and-capability-detection.md`.
- Live-fire proof: `LF-011` `protocol-negotiation-matrix`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-011`.

## EP-012: Terminal, Workspace, UI, and Accessibility Foundation

Add WireMudder Qt surfaces and workspace persistence while preserving terminal authority, capture panes, dashboards, themes, command palette, keyboard operation, screen-reader semantics, and degraded states.

- Dependencies: EP-009.
- Specifications: SPEC-005, SPEC-007, SPEC-018, SPEC-027.
- ExecPlan: `.agent/execplans/EP-012-terminal-workspace-ui-and-accessibility-foundation.md`.
- Live-fire proof: `LF-012` `terminal-workspace-flow`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-012`.

## EP-013: Mapper, World Graph, and Routing

Preserve advanced mapper behavior, add typed world-graph events, confidence and corrections, benchmark routing, and prepare World Brain integration without replacing the inherited map.

- Dependencies: EP-009.
- Specifications: SPEC-005, SPEC-012, SPEC-021, SPEC-027.
- ExecPlan: `.agent/execplans/EP-013-mapper-world-graph-and-routing.md`.
- Live-fire proof: `LF-013` `mapper-route-roundtrip`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-013`.

## EP-014: Local Storage, Transcripts, Search, and Backup

Implement WireCore local persistence, append-only transcript metadata, FTS, selected vector indexing, migrations, backup, restore, export, deletion, and queue isolation.

- Dependencies: EP-006, EP-009.
- Specifications: SPEC-010, SPEC-011, SPEC-023, SPEC-025, SPEC-026.
- ExecPlan: `.agent/execplans/EP-014-local-storage-transcripts-search-and-backup.md`.
- Live-fire proof: `LF-014` `storage-export-restore`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-014`.

## EP-015: Context Distillation and Token Budget

Implement deterministic event distillation, compact cited context capsules, redaction integration, token and cost budgets, explanations of context selection, and regression fixtures.

- Dependencies: EP-009, EP-014.
- Specifications: SPEC-003, SPEC-010, SPEC-013, SPEC-023.
- ExecPlan: `.agent/execplans/EP-015-context-distillation-and-token-budget.md`.
- Live-fire proof: `LF-015` `distilled-context-budget`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-015`.

## EP-016: AI Provider Router and Adapters

Implement provider-neutral local and remote adapters, privacy and budget routing, health, streaming, cancellation, fallback, evaluation, and certification without requiring remote services for core operation.

- Dependencies: EP-006, EP-015.
- Specifications: SPEC-010, SPEC-013, SPEC-022, SPEC-025, SPEC-026.
- ExecPlan: `.agent/execplans/EP-016-ai-provider-router-and-adapters.md`.
- Live-fire proof: `LF-016` `provider-routing-fallback`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-016`.

## EP-017: Player Copilot, Explanations, and Confidence

Implement suggestion-only Player Copilot, cited Why explanations, calibrated confidence, uncertainty, cancellation, and visible context/privacy/cost disclosures.

- Dependencies: EP-008, EP-016.
- Specifications: SPEC-009, SPEC-013, SPEC-014.
- ExecPlan: `.agent/execplans/EP-017-player-copilot-explanations-and-confidence.md`.
- Live-fire proof: `LF-017` `copilot-suggestion-explanation`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-017`.

## EP-018: Soul, Agent Council, Skills, and Memory Permissions

Implement Soul documents and Studio, specialized agent registry, Agent Skill Tree, memory permissions, council orchestration, policy precedence, and evaluation metadata.

- Dependencies: EP-006, EP-017.
- Specifications: SPEC-010, SPEC-014, SPEC-022.
- ExecPlan: `.agent/execplans/EP-018-soul-agent-council-skills-and-memory-permissions.md`.
- Live-fire proof: `LF-018` `soul-agent-permission`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-018`.

## EP-019: Guarded Autopilot and Action Queue

Implement opt-in guarded autopilot as visible bounded Action Proposals, stale-state detection, rate limits, confirmations, pause/cancel, and audit under the deterministic command gateway.

- Dependencies: EP-008, EP-018.
- Specifications: SPEC-009, SPEC-014, SPEC-022.
- ExecPlan: `.agent/execplans/EP-019-guarded-autopilot-and-action-queue.md`.
- Live-fire proof: `LF-019` `guarded-autopilot-confirmation`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-019`.

## EP-020: Quest Compass, Tactical HUD, and Personal Narrator

Implement cited quest tracking, bounded tactical snapshots, spoken or text Personal Narrator, corrections, uncertainty, and no-command-by-itself behavior.

- Dependencies: EP-013, EP-014, EP-017.
- Specifications: SPEC-012, SPEC-013, SPEC-014, SPEC-015.
- ExecPlan: `.agent/execplans/EP-020-quest-compass-tactical-hud-and-personal-narrator.md`.
- Live-fire proof: `LF-020` `quest-tactical-narration`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-020`.

## EP-021: World Brain, World Bible, and Time Machine

Implement provenance-aware world memory, confidence, corrections, World Bible continuity, selected retrieval, Time Machine snapshots, import/export, and privacy-scoped sharing.

- Dependencies: EP-013, EP-014, EP-015.
- Specifications: SPEC-010, SPEC-011, SPEC-012, SPEC-023.
- ExecPlan: `.agent/execplans/EP-021-world-brain-world-bible-and-time-machine.md`.
- Live-fire proof: `LF-021` `world-memory-correction`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-021`.

## EP-022: Macro Forge, Trigger Lab, and AI Debugger

Implement Macro Forge, Trigger Test Lab, replay-driven script debugging, variable inspection, event timeline, AI-assisted diagnosis, performance statistics, and safe patch proposals.

- Dependencies: EP-010, EP-017, EP-021.
- Specifications: SPEC-008, SPEC-014, SPEC-019.
- ExecPlan: `.agent/execplans/EP-022-macro-forge-trigger-lab-and-ai-debugger.md`.
- Live-fire proof: `LF-022` `macro-trigger-debug`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-022`.

## EP-023: Multi-Session, Headless CLI, and Supervisor

Implement independent session fairness, headless runtime, schema-validated scenarios, JSONL output, supervisor dashboard, controlled cross-session rules, and global emergency stop.

- Dependencies: EP-008, EP-009, EP-014.
- Specifications: SPEC-004, SPEC-009, SPEC-017, SPEC-024.
- ExecPlan: `.agent/execplans/EP-023-multi-session-headless-cli-and-supervisor.md`.
- Live-fire proof: `LF-023` `headless-multisession`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-023`.

## EP-024: Ambient Voice Companion and Voice Macros

Implement push-to-talk voice, local-first STT/TTS, optional approved remote providers, visible mic state, voice macros through Action Proposals, agent voice styles, cancellation, subtitles, and load shedding.

- Dependencies: EP-006, EP-008, EP-016, EP-023.
- Specifications: SPEC-009, SPEC-010, SPEC-015, SPEC-017, SPEC-022.
- ExecPlan: `.agent/execplans/EP-024-ambient-voice-companion-and-voice-macros.md`.
- Live-fire proof: `LF-024` `voice-privacy-command`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-024`.

## EP-025: Retro Renderer, Diorama, and Visual Emits

Implement original retro room backdrops, diorama or tile/sprite surfaces, visual emit extraction, overlays, clickable exits, provenance, confidence, caching, frame budgets, and static/text fallback.

- Dependencies: EP-012, EP-015, EP-021.
- Specifications: SPEC-004, SPEC-007, SPEC-012, SPEC-016, SPEC-022.
- ExecPlan: `.agent/execplans/EP-025-retro-renderer-diorama-and-visual-emits.md`.
- Live-fire proof: `LF-025` `renderer-degradation`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-025`.

## EP-026: Soundscape Engine and Audio Studio

Implement room, area, combat, boss, weather, death, victory, and ambience soundscape bindings, local asset packs, studio controls, transitions, provenance, cancellation, and text-preserving degradation.

- Dependencies: EP-024, EP-025.
- Specifications: SPEC-004, SPEC-015, SPEC-016, SPEC-022.
- ExecPlan: `.agent/execplans/EP-026-soundscape-engine-and-audio-studio.md`.
- Live-fire proof: `LF-026` `soundscape-degradation`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-026`.

## EP-027: Contextual Help, Setup Coach, and Source Index

Implement help bubbles, safe defaults, validation/privacy guidance, local Help Knowledge Index, Ask WireMudder AI, world capability onboarding, CLI parity, and opt-in source indexing without mutation authority.

- Dependencies: EP-006, EP-012, EP-016.
- Specifications: SPEC-007, SPEC-010, SPEC-018, SPEC-022.
- ExecPlan: `.agent/execplans/EP-027-contextual-help-setup-coach-and-source-index.md`.
- Live-fire proof: `LF-027` `help-coach-no-side-effects`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-027`.

## EP-028: Telemetry, Replay, and Diagnostic Bundles

Implement local structured telemetry, ring buffers, redaction, fingerprints, session replay, diagnostic preview/export, health metrics, and sanitized fixture generation.

- Dependencies: EP-003, EP-006, EP-014.
- Specifications: SPEC-010, SPEC-019, SPEC-023, SPEC-026.
- ExecPlan: `.agent/execplans/EP-028-telemetry-replay-and-diagnostic-bundles.md`.
- Live-fire proof: `LF-028` `diagnostic-bundle-redaction`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-028`.

## EP-029: Bounded Bug Automation and Remediation

Implement evidence-backed bug intake, deduplication, reproduction, diagnosis, patch planning, independent review, canary recommendation, rollback, and terminal BLOCKED behavior for future autonomous remediation.

- Dependencies: EP-022, EP-028.
- Specifications: SPEC-019, SPEC-022, SPEC-025, SPEC-027.
- ExecPlan: `.agent/execplans/EP-029-bounded-bug-automation-and-remediation.md`.
- Live-fire proof: `LF-029` `bug-remediation-replay`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-029`.

## EP-030: Imports, Migrations, and Client Ecosystem

Implement safe migration from Mudlet assets and evidence-backed import paths for MUSHclient, TinTin++, zMUD/CMUD concepts, and generic formats with disabled automation and rollback.

- Dependencies: EP-010, EP-013, EP-014.
- Specifications: SPEC-005, SPEC-008, SPEC-011, SPEC-021, SPEC-022.
- ExecPlan: `.agent/execplans/EP-030-imports-migrations-and-client-ecosystem.md`.
- Live-fire proof: `LF-030` `import-migration-disabled-automation`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-030`.

## EP-031: Accessibility, Localization, and UX Hardening

Complete keyboard, focus, screen-reader, non-color state, reduced-motion, large-text, subtitles, spoken feedback, raw-text fallback, translation, and usability testing across all enabled surfaces.

- Dependencies: EP-012, EP-024, EP-025.
- Specifications: SPEC-007, SPEC-015, SPEC-016, SPEC-018, SPEC-027.
- ExecPlan: `.agent/execplans/EP-031-accessibility-localization-and-ux-hardening.md`.
- Live-fire proof: `LF-031` `accessibility-keyboard-screenreader`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-031`.

## EP-032: Performance, Benchmarks, Degradation, and Fairness

Run the full performance constitution, establish hardware baselines, enforce P0/P1 budgets, validate queue behavior and session fairness, and prove degradation of every optional subsystem.

- Dependencies: EP-009, EP-015, EP-023, EP-024, EP-025, EP-026.
- Specifications: SPEC-004, SPEC-027.
- ExecPlan: `.agent/execplans/EP-032-performance-benchmarks-degradation-and-fairness.md`.
- Live-fire proof: `LF-032` `performance-priority-flood`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-032`.

## EP-033: Security, Threat Model, License, SBOM, and Supply Chain

Complete threat models, secrets and dependency scans, package and asset policy, prompt-injection defenses, SBOM, provenance, GPL/source obligations, forced failures, and release-blocking security review.

- Dependencies: EP-006, EP-008, EP-010, EP-011, EP-014, EP-016, EP-028, EP-030, EP-032.
- Specifications: SPEC-001, SPEC-020, SPEC-022, SPEC-027, SPEC-028.
- ExecPlan: `.agent/execplans/EP-033-security-threat-model-license-sbom-and-supply-chain.md`.
- Live-fire proof: `LF-033` `security-supply-chain-denial`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-033`.

## EP-034: Secure Updater, Package Registry, and Rollback

Implement signed core and asset manifests, separate update lanes, channel policy, resumable downloads, permission review, health confirmation, migration safety, staged rollout metadata, quarantine, and rollback.

- Dependencies: EP-010, EP-033.
- Specifications: SPEC-010, SPEC-020, SPEC-022, SPEC-025.
- ExecPlan: `.agent/execplans/EP-034-secure-updater-package-registry-and-rollback.md`.
- Live-fire proof: `LF-034` `signed-update-rollback`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-034`.

## EP-035: Installers, CI, Release Channels, and Artifacts

Adapt inherited cross-platform CI and packaging, produce WireMudder source and binaries, checksums, signatures, provenance, SBOM, channel metadata, smoke tests, and manual publishing instructions.

- Dependencies: EP-031, EP-032, EP-034.
- Specifications: SPEC-001, SPEC-020, SPEC-026, SPEC-028.
- ExecPlan: `.agent/execplans/EP-035-installers-ci-release-channels-and-artifacts.md`.
- Live-fire proof: `LF-035` `installer-release-channel`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-035`.

## EP-036: Platform Certification, Chaos, and Upstream Sync Regression

Certify clean Windows, macOS, and Linux flows; exercise dependency, process, network, storage, provider, package, update, and resource faults; and prove an upstream sync does not break contracts.

- Dependencies: EP-003, EP-011, EP-012, EP-023, EP-035.
- Specifications: SPEC-001, SPEC-005, SPEC-006, SPEC-017, SPEC-021, SPEC-027, SPEC-028.
- ExecPlan: `.agent/execplans/EP-036-platform-certification-chaos-and-upstream-sync-regression.md`.
- Live-fire proof: `LF-036` `platform-chaos-matrix`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-036`.

## EP-037: Documentation, Package Developer, and Community Ecosystem

Complete user, administrator, package author, importer, accessibility, privacy, troubleshooting, headless, API, build, contribution, upstream, release, and support documentation with examples that match tested contracts.

- Dependencies: EP-010, EP-027, EP-030, EP-036.
- Specifications: SPEC-000, SPEC-008, SPEC-018, SPEC-021, SPEC-026, SPEC-028.
- ExecPlan: `.agent/execplans/EP-037-documentation-package-developer-and-community-ecosystem.md`.
- Live-fire proof: `LF-037` `package-developer-workflow`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-037`.

## EP-038: Full Release Candidate Hardening

Freeze a release candidate, run all applicable Graphlock, compatibility, performance, accessibility, security, privacy, supply-chain, installer, update, backup, restore, import, and live-fire gates, and produce an evidence index and known-risk report.

- Dependencies: EP-029, EP-032, EP-033, EP-035, EP-036, EP-037.
- Specifications: SPEC-000, SPEC-020, SPEC-022, SPEC-027, SPEC-028.
- ExecPlan: `.agent/execplans/EP-038-full-release-candidate-hardening.md`.
- Live-fire proof: `LF-038` `release-candidate-full-suite`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-038`.

## EP-039: Production Readiness, Ship, and Run Complete

Run the final fresh ship gate, verify evidence hashes and release profile claims, create the release tag and manual signing/publishing packet, append RUN_COMPLETE, and leave production unpublished because auto-deploy is not authorized.

- Dependencies: EP-038.
- Specifications: SPEC-000, SPEC-020, SPEC-028.
- ExecPlan: `.agent/execplans/EP-039-production-readiness-ship-and-run-complete.md`.
- Live-fire proof: `LF-039` `ship-gate`.
- Exit: milestone evidence, node verifier sentinel, expected-file audit, `NODE_DONE`, and `green/EP-039`.
