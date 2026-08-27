# WireMudder Architecture

## 1. Purpose

This document defines the runtime and repository architecture that replaces the first-generation greenfield Tauri plan. It preserves mature Mudlet behavior, isolates optional systems, creates verifiable boundaries, and prevents future agents from converting product intent into invented source paths or APIs.

## 2. Verified Inherited Foundation

The evidence snapshot in `UPSTREAM.lock.yaml` identifies the official Mudlet repository and pinned commit. Current upstream instructions describe a cross-platform Qt6 and C++20 application with Lua 5.1 scripting, CMake presets, a main application, Host profile and connection management, Telnet handling, terminal console, Lua interpreter, and mapper. EP-000 verifies these facts in the actual target repository.

The inherited foundation owns initially:

- Application shell and Qt lifecycle.
- Profiles and connections.
- Telnet and current protocol handling.
- Terminal, input, scrollback, history, selection, and logging.
- Lua 5.1 runtime and public Lua API.
- Aliases, triggers, timers, macros, keys, scripts, variables, and packages.
- Mapper and associated import/export behavior.
- Existing desktop layouts, editors, dialogs, accessibility, localization, CI, and installers.

## 3. Target Runtime

```text
MUD server
  -> inherited Mudlet network and protocol path
  -> inherited terminal and classic automation path
  -> minimal WireMudder event bridge
  -> bounded local IPC
  -> isolated Rust WireCore
       -> privacy and consent
       -> profiles and command policy
       -> storage and memory
       -> context distillation and AI routing
       -> headless supervisor
       -> voice workers
       -> renderer and sound workers
       -> replay, diagnostics, and update services
```

Manual gameplay does not depend on WireCore. If WireCore is absent, hung, restarting, incompatible, denied, or disabled, inherited connection, terminal, manual commands, classic automation, mapper, and profile behavior continue according to the selected release profile.

## 4. Repository Map

| Path | Owner | Import or Dependency Rule |
| --- | --- | --- |
| Existing upstream paths | Mudlet inherited core | Changed minimally and only with source evidence and a discovered-path fence. |
| `src/wiremudder/` | Qt/C++ integration and UI | May depend on verified Mudlet public or internal integration points and generated contracts; never contains model or durable-memory logic. |
| `wirecore/crates/` | Rust domain and workers | May depend on generated contracts and adapter interfaces; never includes Qt or direct Mudlet source. |
| `schemas/wiremudder/` | Canonical cross-language contracts | Imported by generators and validators; generated bindings are not hand edited. |
| `compatibility/` | Independent oracle fixtures | May inspect reference and candidate output; production code does not import tests. |
| `tests/wiremudder/` | WireMudder tests | Test doubles remain here; real controlled dependencies are used for integration and live-fire. |
| `tools/` | Protocol Museum, import, schema, diagnostic, and release tools | Tools do not become runtime dependencies unless promoted through an ADR. |
| `.agent/` | Graphlock control, specs, graph, plans, contracts, state, and evidence | Product code never imports Graphlock files. |

## 5. Runtime Priority Rings

| Ring | Responsibilities | Degradation |
| --- | --- | --- |
| P0 | Connection delivery, terminal output, manual input, outbound send, emergency stop | Never blocked. Preserve reserved capacity. |
| P1 | Protocol parsing, classic automation, mapper-critical events, command safety | Bound and measured. Quarantine slow work. |
| P2 | Context, memory hot cache, quest, tactical, Copilot, guarded proposals | Snapshot, delay, reduce, pause, or disable. |
| P3 | Voice, renderer, emits, narrator, soundscapes | Cancel, drop, coalesce, freeze, or disable. |
| P4 | Indexing, compaction, updates, package checks, source/help indexing, telemetry export | Idle-only, resumable, or manually started. |

`PERFORMANCE_CONSTITUTION.md` is binding.

## 6. Native Bridge Boundary

The native bridge is deliberately small. It publishes normalized snapshots and events, accepts typed non-manual Action Proposals and optional UI data, tracks WireCore health, and applies bounded transport policy. It does not call models, write long-term memory, select network routes, store provider credentials, interpret Soul documents, or bypass command safety.

The bridge must use asynchronous Qt facilities and cannot synchronously wait for WireCore. Local transport and encoding are selected in EP-005 after benchmark and repository evidence, then pinned by ADR. The blueprint does not invent a Rust or Qt library API before that evidence exists.

## 7. WireCore Boundaries

WireCore is an isolated process composed of narrowly owned crates. Domain crates depend inward on contracts and pure policy. Adapters depend outward on storage, model, speech, renderer, and update providers. A provider SDK cannot appear in a core domain contract.

Workers expose health, readiness, cancellation, budget, queue, and shutdown behavior. Optional worker failure is contained and reported. WireCore never owns the inherited socket or terminal.

## 8. State and Persistence

- Current gameplay state uses bounded snapshots and in-memory caches.
- Transcript data is append-only and indexed asynchronously.
- Structured data uses a pinned local database selected and proven in EP-014, with SQLite as the default candidate.
- FTS indexes approved text.
- Vector indexing covers selected facts and summaries only.
- Secrets use OS-backed secure storage or a separately approved encrypted fallback.
- Audit, privacy, action, routing, update, and diagnostic events are append-only or tamper-evident according to their contract.
- Export, backup, restore, migration, deletion, and index rebuild are first-class flows.

## 9. Action and Authority Boundary

Every non-manual command enters SPEC-009. No model, Soul document, plugin, package, voice transcript, renderer interaction, headless rule, or cross-session workflow can send directly. Routing and sensitive profile defaults are user-controlled. Emergency stop has reserved P0 capacity.

## 10. Privacy Boundary

Remote egress passes deterministic policy before any provider call. Privacy Firewall shows the exact approved context and redactions. Local Only Lockdown blocks declared remote routes and downloads. Secrets never enter AI, logs, diagnostics, source indexes, packages, renderer prompts, or voice transcripts.

## 11. Compatibility and Replacement Boundary

Mudlet is a reference implementation and inherited production foundation. Any replacement follows this sequence:

1. Pin source and observable behavior.
2. Create independent fixtures and semantic comparison.
3. Implement behind a disabled feature flag.
4. Run contract, differential, fuzz, performance, security, migration, and failure tests.
5. Canary with immediate rollback.
6. Keep the inherited implementation through at least one stable release.
7. Remove only by ADR after measured evidence and upstream-sync review.

## 12. External Integration Boundary

AI, speech, asset, package, telemetry, and update providers are optional adapters. The core product has no mandatory cloud account. Every adapter declares privacy, cost, health, limits, license, provenance, certification, and disabled behavior. Uncertified adapters are unavailable rather than simulated.

## 13. Error and Recovery Boundary

Typed errors, correlation, bounded retries, cancellation, quarantine, compensation, rollback, and user-safe messages follow SPEC-025. Security, privacy, routing, command, update, and signing ambiguity fails closed. Optional subsystem failure preserves text gameplay.

## 14. Observability Boundary

Only bounded counters and ring-buffer events are permitted near hot paths. Compression, export, indexing, and remote submission are P4. Diagnostics are local, redacted, previewable, and user-controlled.

## 15. Architectural Invariants

- `WM-ARCH-001`: A full greenfield rewrite is forbidden.
- `WM-ARCH-002`: Mudlet remains the initial terminal, Lua, profile, package, mapper, and desktop implementation.
- `WM-ARCH-003`: P0 never waits on WireCore or a remote service.
- `WM-ARCH-004`: Inherited-source edits require source evidence and an expected-file amendment.
- `WM-ARCH-005`: Public names come from canonical vocabulary and schemas.
- `WM-ARCH-006`: Every optional feature has a gameplay-preserving fallback.
- `WM-ARCH-007`: Every non-manual command uses the Action Proposal gateway.
- `WM-ARCH-008`: AI and automation cannot modify routing or sensitive defaults.
- `WM-ARCH-009`: Secrets never enter model, plugin, package, log, diagnostic, help, renderer, or voice context.
- `WM-ARCH-010`: An uncertified provider or platform is disabled and unadvertised.
- `WM-ARCH-011`: A replacement remains reversible through at least one stable release.
- `WM-ARCH-012`: No gate is weakened to make implementation pass.
- `WM-ARCH-013`: Runtime claims require observed evidence.
- `WM-ARCH-014`: Maintainer-controlled signing and legal decisions remain outside agents.
- `WM-ARCH-015`: Upstream history, attribution, and source obligations are preserved.

## 16. Forbidden Moves

- Copying Mudlet into an unrelated empty repository.
- Introducing Tauri or React as the first desktop shell.
- Renaming broad inherited namespaces or moving source for branding.
- Writing new behavior directly from the old roadmap or conversation.
- Inventing source paths, classes, Lua APIs, build flags, protocol behavior, or package formats.
- Direct command sending from AI, voice, plugins, renderer, or headless rules.
- Silent direct-network fallback.
- Mandatory cloud login.
- Hidden telemetry or microphone capture.
- Provider simulation in production paths.
- Protected asset or voice imitation without lawful provenance.

## 17. Adding a Feature

Add or update the feature row, accepted spec requirement, node contract, expected paths, tests, live-fire proof, privacy and performance classification, failure fallback, documentation, and release profile before production code. A feature with no trace row cannot merge.

## 18. Adding an Inherited-Source Edit

Record source evidence, create the node's discovered expected-file amendment, cite the invariant and integration point, add a reference regression fixture, make the smallest patch, and run upstream compatibility and scope audits.

## 19. Adding a Dependency

Verify no existing dependency satisfies the need. Record exact version, source, license, maintenance state, platform support, supply-chain risk, size, performance, and rollback in an ADR. Pin it and update SBOM and build documentation.

## 20. Architecture Review Checklist

- Does the change preserve the fork-first model?
- Is every inherited symbol evidence-backed?
- Is P0 isolated?
- Is the boundary typed and versioned?
- Are authority, privacy, secrets, and routing protected?
- Are queues, cancellation, failure, and fallback defined?
- Are compatibility, performance, security, accessibility, migration, and rollback proven?
- Is the feature matrix updated?
- Is upstream divergence minimized?
- Is the release claim honest?
