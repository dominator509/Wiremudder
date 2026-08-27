# WireMudder Feature Catalog

## Authority

The machine-readable authority is `.agent/features/FEATURES.tsv`. This document groups the same 244 features for humans. Every row has a stable feature ID, accepted specification, owning node, test path, proof, source reference, release profile, and status.

## Completeness Rules

- A feature cannot be deleted without an ADR, source-coverage update, specification update, graph compatibility review, and explicit user decision.
- A feature cannot be marked implemented or certified without observed evidence.
- Research features finish with an evidence-backed implement, defer, or reject decision.
- Optional provider adapters remain disabled until live-fire certification.
- The feature coverage gate runs in every final review and release candidate.
## AI

- `WM-FEAT-0181` Mapper and Cartographer Agent - `SPEC-014` / `EP-018` / `LF-018` / profile `ai` / status `required`.
- `WM-FEAT-0182` Lore and Memory Curator Agent - `SPEC-014` / `EP-018` / `LF-018` / profile `ai` / status `required`.
- `WM-FEAT-0183` Quest Agent - `SPEC-014` / `EP-020` / `LF-020` / profile `ai` / status `required`.
- `WM-FEAT-0184` Tactical Agent - `SPEC-014` / `EP-020` / `LF-020` / profile `ai` / status `required`.
- `WM-FEAT-0185` Renderer Scene Agent - `SPEC-014` / `EP-025` / `LF-025` / profile `immersion` / status `required`.
- `WM-FEAT-0186` Voice Companion Agent - `SPEC-014` / `EP-024` / `LF-024` / profile `immersion` / status `required`.
- `WM-FEAT-0187` Contextual Help and Setup Coach Agent - `SPEC-014` / `EP-027` / `LF-027` / profile `developer` / status `required`.
- `WM-FEAT-0188` Command Safety Agent - `SPEC-014` / `EP-008` / `LF-008` / profile `core` / status `required`.
- `WM-FEAT-0189` Token Budget Agent - `SPEC-014` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0190` Privacy Firewall Agent - `SPEC-014` / `EP-006` / `LF-006` / profile `core` / status `required`.

## AI and Memory

- `WM-FEAT-0037` local and remote AI provider adapters - `SPEC-013` / `EP-016` / `LF-016` / profile `full` / status `required`.
- `WM-FEAT-0038` AI Provider Router - `SPEC-013` / `EP-016` / `LF-016` / profile `full` / status `required`.
- `WM-FEAT-0039` privacy modes - `SPEC-014` / `EP-017` / `LF-017` / profile `full` / status `required`.
- `WM-FEAT-0040` Player Copilot - `SPEC-014` / `EP-017` / `LF-017` / profile `full` / status `required`.
- `WM-FEAT-0041` Guarded Autopilot - `SPEC-014` / `EP-019` / `LF-019` / profile `full` / status `required`.
- `WM-FEAT-0042` Soul.md personas - `SPEC-014` / `EP-018` / `LF-018` / profile `full` / status `required`.
- `WM-FEAT-0043` Soul.md Studio - `SPEC-014` / `EP-018` / `LF-018` / profile `full` / status `required`.
- `WM-FEAT-0044` Agent Skill Tree - `SPEC-014` / `EP-018` / `LF-018` / profile `full` / status `required`.
- `WM-FEAT-0045` Agent Council - `SPEC-014` / `EP-018` / `LF-018` / profile `full` / status `required`.
- `WM-FEAT-0046` AI Confidence Meter - `SPEC-014` / `EP-017` / `LF-017` / profile `full` / status `required`.
- `WM-FEAT-0047` AI `Why?` explanations - `SPEC-014` / `EP-017` / `LF-017` / profile `full` / status `required`.
- `WM-FEAT-0048` Context Distillation Engine - `SPEC-013` / `EP-015` / `LF-015` / profile `full` / status `required`.
- `WM-FEAT-0049` Token Budget Dashboard - `SPEC-013` / `EP-015` / `LF-015` / profile `full` / status `required`.
- `WM-FEAT-0050` World Brain - `SPEC-012` / `EP-021` / `LF-021` / profile `full` / status `required`.
- `WM-FEAT-0051` World Bible - `SPEC-012` / `EP-021` / `LF-021` / profile `full` / status `required`.
- `WM-FEAT-0052` RAG memory - `SPEC-012` / `EP-021` / `LF-021` / profile `full` / status `required`.
- `WM-FEAT-0053` Time Machine Memory - `SPEC-012` / `EP-021` / `LF-021` / profile `full` / status `required`.
- `WM-FEAT-0054` Quest Compass - `SPEC-014` / `EP-020` / `LF-020` / profile `full` / status `required`.
- `WM-FEAT-0055` Tactical HUD - `SPEC-014` / `EP-020` / `LF-020` / profile `full` / status `required`.
- `WM-FEAT-0056` Personal Narrator - `SPEC-014` / `EP-020` / `LF-020` / profile `full` / status `required`.

## Architecture

- `WM-FEAT-0155` Minimal Qt and C++ native bridge - `SPEC-002` / `EP-005` / `LF-005` / profile `core` / status `required`.
- `WM-FEAT-0156` Isolated Rust WireCore sidecar - `SPEC-002` / `EP-005` / `LF-005` / profile `core` / status `required`.
- `WM-FEAT-0157` Local authenticated versioned IPC - `SPEC-024` / `EP-005` / `LF-005` / profile `core` / status `required`.
- `WM-FEAT-0158` WireCore crash and hang isolation - `SPEC-002` / `EP-005` / `LF-005` / profile `core` / status `required`.
- `WM-FEAT-0159` Reversible strangler migration for any inherited replacement - `SPEC-002` / `EP-036` / `LF-036` / profile `release` / status `required`.
- `WM-FEAT-0160` No mass rename or broad source reorganization - `SPEC-001` / `EP-002` / `LF-002` / profile `core` / status `required`.

## Classic Client

- `WM-FEAT-0001` terminal pane - `SPEC-007` / `EP-012` / `LF-012` / profile `full` / status `required`.
- `WM-FEAT-0002` ANSI/xterm/truecolor support path - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0003` scrollback - `SPEC-007` / `EP-012` / `LF-012` / profile `full` / status `required`.
- `WM-FEAT-0004` command history - `SPEC-007` / `EP-012` / `LF-012` / profile `full` / status `required`.
- `WM-FEAT-0005` aliases - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0006` triggers - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0007` timers - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0008` macros/hotkeys - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0009` speed-walking - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0010` speedwalk throttling - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0011` capture/output panes - `SPEC-007` / `EP-012` / `LF-012` / profile `full` / status `required`.
- `WM-FEAT-0012` status bars/gauges - `SPEC-007` / `EP-012` / `LF-012` / profile `full` / status `required`.
- `WM-FEAT-0013` variables/state tables - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0014` trigger wizard - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0015` command input triggers - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0016` gag/highlight/substitute triggers - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0017` multi-state triggers - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0018` spellcheck/autocorrect - `SPEC-007` / `EP-012` / `LF-012` / profile `full` / status `required`.
- `WM-FEAT-0019` tab/entity/command-template completion - `SPEC-007` / `EP-012` / `LF-012` / profile `full` / status `required`.
- `WM-FEAT-0020` logging/transcripts - `SPEC-005` / `EP-009` / `LF-009` / profile `full` / status `required`.
- `WM-FEAT-0021` layouts, panes, dashboards, themes - `SPEC-007` / `EP-012` / `LF-012` / profile `full` / status `required`.
- `WM-FEAT-0161` script debugger and variable inspector - `SPEC-008` / `EP-022` / `LF-022` / profile `ai` / status `required`.
- `WM-FEAT-0162` event replay for scripts and triggers - `SPEC-008` / `EP-022` / `LF-022` / profile `ai` / status `required`.
- `WM-FEAT-0163` slow trigger and pathological regex quarantine - `SPEC-004` / `EP-032` / `LF-032` / profile `core` / status `required`.
- `WM-FEAT-0164` builder tools - `SPEC-008` / `EP-037` / `LF-037` / profile `core` / status `required`.

## Command Safety

- `WM-FEAT-0174` per-world command schema and risk tiers - `SPEC-009` / `EP-008` / `LF-008` / profile `core` / status `required`.
- `WM-FEAT-0175` known-safe and known-dangerous command policies - `SPEC-009` / `EP-008` / `LF-008` / profile `core` / status `required`.
- `WM-FEAT-0176` argument validation and deny allow rules - `SPEC-009` / `EP-008` / `LF-008` / profile `core` / status `required`.
- `WM-FEAT-0177` destructive action confirmation - `SPEC-009` / `EP-008` / `LF-008` / profile `core` / status `required`.
- `WM-FEAT-0178` visible AI command queue - `SPEC-009` / `EP-008` / `LF-008` / profile `core` / status `required`.
- `WM-FEAT-0179` audit of suggestion command pacing approval and send result - `SPEC-009` / `EP-008` / `LF-008` / profile `core` / status `required`.
- `WM-FEAT-0180` prompt injection defenses before automated commands - `SPEC-009` / `EP-008` / `LF-008` / profile `core` / status `required`.

## Context

- `WM-FEAT-0196` typed RoomSeen event - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0197` typed ExitSeen event - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0198` typed MobSeen event - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0199` typed PlayerSeen event - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0200` typed AnimalSeen event - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0201` typed PKerOrPvPerSeen event - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0202` typed CombatStarted and CombatEnded events - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0203` typed ItemSeen and QuestClueSeen events - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0204` typed PromptSeen and HealthChanged events - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0205` typed CommandSucceeded and CommandFailed events - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0206` typed SocialMessageSeen and redacted private message events - `SPEC-003` / `EP-015` / `LF-015` / profile `ai` / status `required`.
- `WM-FEAT-0207` typed RendererEmitCandidate event - `SPEC-003` / `EP-025` / `LF-025` / profile `immersion` / status `required`.

## Governance

- `WM-FEAT-0146` Mudlet fork with preserved Git history - `SPEC-001` / `EP-001` / `LF-001` / profile `core` / status `required`.
- `WM-FEAT-0147` Pinned upstream commit and stable release evidence - `SPEC-001` / `EP-000` / `LF-000` / profile `core` / status `required`.
- `WM-FEAT-0148` Upstream synchronization rehearsal and rollback - `SPEC-001` / `EP-002` / `LF-002` / profile `core` / status `required`.
- `WM-FEAT-0149` Patch classification for upstreamable, bridge, feature, branding, and security changes - `SPEC-001` / `EP-002` / `LF-002` / profile `core` / status `required`.
- `WM-FEAT-0150` Source evidence registry for every external symbol and command - `SPEC-003` / `EP-000` / `LF-000` / profile `core` / status `required`.
- `WM-FEAT-0151` Feature coverage gate - `SPEC-000` / `EP-004` / `LF-004` / profile `core` / status `required`.
- `WM-FEAT-0152` Specification requirement trace gate - `SPEC-003` / `EP-004` / `LF-004` / profile `core` / status `required`.
- `WM-FEAT-0153` Expected-file scope fence with evidence-backed brownfield amendments - `SPEC-003` / `EP-004` / `LF-004` / profile `core` / status `required`.
- `WM-FEAT-0154` Append-only ledger, lease, scheduler, green tags, and bounded retries - `SPEC-000` / `EP-001` / `LF-001` / profile `core` / status `required`.

## Headless, Replay, and Developer

- `WM-FEAT-0121` CLI/headless sessions - `SPEC-017` / `EP-023` / `LF-023` / profile `full` / status `required`.
- `WM-FEAT-0122` scenario files - `SPEC-017` / `EP-023` / `LF-023` / profile `full` / status `required`.
- `WM-FEAT-0123` JSONL event output - `SPEC-017` / `EP-023` / `LF-023` / profile `full` / status `required`.
- `WM-FEAT-0124` Headless Supervisor Dashboard - `SPEC-017` / `EP-023` / `LF-023` / profile `full` / status `required`.
- `WM-FEAT-0125` multi-session orchestration rules - `SPEC-017` / `EP-023` / `LF-023` / profile `full` / status `required`.
- `WM-FEAT-0126` Session Replay - `SPEC-019` / `EP-003` / `LF-003` / profile `full` / status `required`.
- `WM-FEAT-0127` AI Debugger - `SPEC-019` / `EP-022` / `LF-022` / profile `full` / status `required`.
- `WM-FEAT-0128` sanitized fixture generator - `SPEC-019` / `EP-028` / `LF-028` / profile `full` / status `required`.
- `WM-FEAT-0129` Compatibility Lab - `SPEC-019` / `EP-003` / `LF-003` / profile `full` / status `required`.
- `WM-FEAT-0130` Protocol Museum fake MUD servers - `SPEC-019` / `EP-003` / `LF-003` / profile `full` / status `required`.
- `WM-FEAT-0131` performance benchmark suite - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0132` local diagnostic bundles - `SPEC-019` / `EP-028` / `LF-028` / profile `full` / status `required`.
- `WM-FEAT-0133` future autonomous bug remediation - `SPEC-019` / `EP-029` / `LF-029` / profile `future` / status `research-decision-required`.

## Help

- `WM-FEAT-0213` circular help bubbles beside fields feature cards wizard steps and advanced controls - `SPEC-018` / `EP-027` / `LF-027` / profile `developer` / status `required`.
- `WM-FEAT-0214` help popovers with safe defaults validation hints privacy notes and documentation links - `SPEC-018` / `EP-027` / `LF-027` / profile `developer` / status `required`.
- `WM-FEAT-0215` Ask WireMudder AI handoff - `SPEC-018` / `EP-027` / `LF-027` / profile `developer` / status `required`.
- `WM-FEAT-0216` local-only and remote-redacted help modes - `SPEC-018` / `EP-027` / `LF-027` / profile `developer` / status `required`.
- `WM-FEAT-0217` generated Help Knowledge Index - `SPEC-018` / `EP-027` / `LF-027` / profile `developer` / status `required`.
- `WM-FEAT-0218` optional local source checkout indexing - `SPEC-018` / `EP-027` / `LF-027` / profile `developer` / status `required`.
- `WM-FEAT-0219` coach cannot directly change protected settings or send commands - `SPEC-018` / `EP-027` / `LF-027` / profile `developer` / status `required`.

## Mapper

- `WM-FEAT-0165` zones and area clustering - `SPEC-012` / `EP-013` / `LF-013` / profile `core` / status `required`.
- `WM-FEAT-0166` custom hidden locked one-way and portal exits - `SPEC-012` / `EP-013` / `LF-013` / profile `core` / status `required`.
- `WM-FEAT-0167` weighted and timed routing - `SPEC-012` / `EP-013` / `LF-013` / profile `core` / status `required`.
- `WM-FEAT-0168` map import export and backups - `SPEC-012` / `EP-013` / `LF-013` / profile `core` / status `required`.

## Memory

- `WM-FEAT-0191` room identity confidence - `SPEC-012` / `EP-021` / `LF-021` / profile `ai` / status `required`.
- `WM-FEAT-0192` user correction and supersession workflow - `SPEC-012` / `EP-021` / `LF-021` / profile `ai` / status `required`.
- `WM-FEAT-0193` current-room hot cache - `SPEC-012` / `EP-021` / `LF-021` / profile `ai` / status `required`.
- `WM-FEAT-0194` entity observations for NPCs mobs animals players and PvP-visible characters - `SPEC-012` / `EP-021` / `LF-021` / profile `ai` / status `required`.
- `WM-FEAT-0195` World Bible region palettes terrain lighting factions silhouettes architecture and roleplay continuity - `SPEC-012` / `EP-021` / `LF-021` / profile `ai` / status `required`.

## Multi-Session and Routing

- `WM-FEAT-0078` multiple tabs/windows - `SPEC-017` / `EP-023` / `LF-023` / profile `full` / status `required`.
- `WM-FEAT-0079` Character Memory Profiles - `SPEC-010` / `EP-007` / `LF-007` / profile `full` / status `required`.
- `WM-FEAT-0080` per-character default network routing profile - `SPEC-006` / `EP-007` / `LF-007` / profile `full` / status `required`.
- `WM-FEAT-0081` direct/system-network profile - `SPEC-017` / `EP-023` / `LF-023` / profile `full` / status `required`.
- `WM-FEAT-0082` SOCKS5 profile - `SPEC-006` / `EP-007` / `LF-007` / profile `full` / status `required`.
- `WM-FEAT-0083` HTTP CONNECT profile - `SPEC-017` / `EP-023` / `LF-023` / profile `full` / status `required`.
- `WM-FEAT-0084` SOCKS4a profile - `SPEC-006` / `EP-007` / `LF-007` / profile `full` / status `required`.
- `WM-FEAT-0085` Tor-compatible local SOCKS endpoint profile - `SPEC-006` / `EP-007` / `LF-007` / profile `full` / status `required`.
- `WM-FEAT-0086` SSH dynamic-forward profile - `SPEC-006` / `EP-007` / `LF-007` / profile `full` / status `required`.
- `WM-FEAT-0087` external VPN metadata profiles for WireGuard/OpenVPN/system VPN routes - `SPEC-006` / `EP-007` / `LF-007` / profile `full` / status `required`.
- `WM-FEAT-0088` future interface binding - `SPEC-006` / `EP-007` / `LF-007` / profile `future` / status `research-decision-required`.
- `WM-FEAT-0089` future VM/container/network namespace profile - `SPEC-006` / `EP-007` / `LF-007` / profile `future` / status `research-decision-required`.
- `WM-FEAT-0090` future self-hosted relay profile - `SPEC-006` / `EP-007` / `LF-007` / profile `future` / status `research-decision-required`.
- `WM-FEAT-0091` explicit egress verification - `SPEC-006` / `EP-007` / `LF-007` / profile `full` / status `required`.
- `WM-FEAT-0092` routing audit log - `SPEC-006` / `EP-007` / `LF-007` / profile `full` / status `required`.

## Operations

- `WM-FEAT-0241` secure source and binary release artifacts with checksums SBOM and provenance - `SPEC-028` / `EP-035` / `LF-035` / profile `release` / status `required`.
- `WM-FEAT-0242` Windows macOS and Linux installer and upgrade certification - `SPEC-028` / `EP-036` / `LF-036` / profile `release` / status `required`.
- `WM-FEAT-0243` backup restore rollback and incident runbooks - `SPEC-026` / `EP-037` / `LF-037` / profile `core` / status `required`.
- `WM-FEAT-0244` core release with optional providers visibly disabled until certification - `SPEC-000` / `EP-038` / `LF-038` / profile `release` / status `required`.

## Performance

- `WM-FEAT-0134` P0/P1/P2/P3/P4 priority rings - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0135` bounded event bus - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0136` terminal frame buffer - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0137` batched IPC/UI updates - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0138` queue metrics - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0139` degradation/fallback per subsystem - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0140` idle-only maintenance - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0141` slow trigger quarantine - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0142` renderer emit dropping/coalescing - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0143` voice cancellation and load shedding - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0144` AI cancellation and provider fallback - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.
- `WM-FEAT-0145` token budget and cost audit - `SPEC-004` / `EP-032` / `LF-032` / profile `full` / status `required`.

## Power User and Ecosystem

- `WM-FEAT-0104` scripting runtime abstraction - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0105` future Lua-compatible path - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0106` script editor/debugger/variable inspector - `SPEC-008` / `EP-022` / `LF-022` / profile `full` / status `required`.
- `WM-FEAT-0107` Macro Forge - `SPEC-008` / `EP-022` / `LF-022` / profile `full` / status `required`.
- `WM-FEAT-0108` Trigger Test Lab - `SPEC-008` / `EP-022` / `LF-022` / profile `full` / status `required`.
- `WM-FEAT-0109` command palette - `SPEC-018` / `EP-027` / `LF-027` / profile `full` / status `required`.
- `WM-FEAT-0110` profile templates - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0111` world onboarding wizard - `SPEC-018` / `EP-027` / `LF-027` / profile `full` / status `required`.
- `WM-FEAT-0112` per-world capability detector - `SPEC-018` / `EP-027` / `LF-027` / profile `full` / status `required`.
- `WM-FEAT-0113` package browser - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0114` world packs - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0115` command packs - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0116` trigger/macro packs - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0117` renderer packs - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0118` soundscape packs - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0119` Soul.md templates - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0120` Mudlet/MUSHclient/TinTin/zMUD/CMUD importers/research paths - `SPEC-021` / `EP-030` / `LF-030` / profile `future` / status `research-decision-required`.

## Privacy

- `WM-FEAT-0220` AI context disclosure with provider token count memory IDs and transcript ranges - `SPEC-010` / `EP-006` / `LF-006` / profile `core` / status `required`.
- `WM-FEAT-0221` user-reviewed diagnostic export - `SPEC-010` / `EP-028` / `LF-028` / profile `developer` / status `required`.
- `WM-FEAT-0222` private tells pages and whispers protected by default - `SPEC-010` / `EP-006` / `LF-006` / profile `core` / status `required`.

## Privacy and Security

- `WM-FEAT-0093` Privacy Firewall - `SPEC-010` / `EP-006` / `LF-006` / profile `full` / status `required`.
- `WM-FEAT-0094` Local Only Lockdown - `SPEC-010` / `EP-006` / `LF-006` / profile `full` / status `required`.
- `WM-FEAT-0095` Secrets Vault - `SPEC-010` / `EP-006` / `LF-006` / profile `full` / status `required`.
- `WM-FEAT-0096` redaction middleware - `SPEC-010` / `EP-006` / `LF-006` / profile `full` / status `required`.
- `WM-FEAT-0097` immutable audit timeline - `SPEC-010` / `EP-006` / `LF-006` / profile `full` / status `required`.
- `WM-FEAT-0098` plugin/package permission firewall - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.
- `WM-FEAT-0099` protected mic/listening state - `SPEC-010` / `EP-006` / `LF-006` / profile `full` / status `required`.
- `WM-FEAT-0100` AI context disclosure - `SPEC-010` / `EP-006` / `LF-006` / profile `full` / status `required`.
- `WM-FEAT-0101` no hidden telemetry - `SPEC-010` / `EP-006` / `LF-006` / profile `full` / status `required`.
- `WM-FEAT-0102` signed updates - `SPEC-020` / `EP-034` / `LF-034` / profile `full` / status `required`.
- `WM-FEAT-0103` signed/provenance-aware packages - `SPEC-008` / `EP-010` / `LF-010` / profile `full` / status `required`.

## Profiles

- `WM-FEAT-0169` per-character AI provider and privacy defaults - `SPEC-010` / `EP-007` / `LF-007` / profile `core` / status `required`.
- `WM-FEAT-0170` per-character renderer and soundscape defaults - `SPEC-010` / `EP-007` / `LF-007` / profile `core` / status `required`.
- `WM-FEAT-0171` per-character macro trigger and script packs - `SPEC-010` / `EP-007` / `LF-007` / profile `core` / status `required`.
- `WM-FEAT-0172` per-character Soul document and command database - `SPEC-010` / `EP-007` / `LF-007` / profile `core` / status `required`.
- `WM-FEAT-0173` audit of sensitive default changes - `SPEC-010` / `EP-007` / `LF-007` / profile `core` / status `required`.

## Protocol

- `WM-FEAT-0022` Telnet basics - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0023` TLS/telnets path - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0024` ANSI/xterm/truecolor - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0025` MCCP - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0026` GMCP - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0027` MSDP - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0028` MSSP - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0029` MXP - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0030` MSP - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0031` MCP/simpleedit path - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0032` NAWS - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0033` CHARSET - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0034` EOR - `SPEC-006` / `EP-011` / `LF-011` / profile `full` / status `required`.
- `WM-FEAT-0035` Pueblo research - `SPEC-006` / `EP-011` / `LF-011` / profile `future` / status `research-decision-required`.
- `WM-FEAT-0036` Simutronics/GSL research - `SPEC-006` / `EP-011` / `LF-011` / profile `future` / status `research-decision-required`.

## Renderer

- `WM-FEAT-0208` clickable and visible exits when available - `SPEC-016` / `EP-025` / `LF-025` / profile `immersion` / status `required`.
- `WM-FEAT-0209` renderer confidence display - `SPEC-016` / `EP-025` / `LF-025` / profile `immersion` / status `required`.
- `WM-FEAT-0210` renderer provenance tracking - `SPEC-016` / `EP-025` / `LF-025` / profile `immersion` / status `required`.

## Renderer and Soundscape

- `WM-FEAT-0069` original retro tile/sprite/diorama renderer - `SPEC-016` / `EP-025` / `LF-025` / profile `full` / status `required`.
- `WM-FEAT-0070` persistent room backdrops - `SPEC-016` / `EP-025` / `LF-025` / profile `full` / status `required`.
- `WM-FEAT-0071` graphical emits for NPCs, mobs, animals, players, PKers/PvPers, items, spells, combat, movement, doors, weather, ambience, and room events - `SPEC-016` / `EP-025` / `LF-025` / profile `full` / status `required`.
- `WM-FEAT-0072` static/low-power/no-animation modes - `SPEC-016` / `EP-025` / `LF-025` / profile `full` / status `required`.
- `WM-FEAT-0073` text-only fallback - `SPEC-016` / `EP-025` / `LF-025` / profile `full` / status `required`.
- `WM-FEAT-0074` style capsules from World Bible - `SPEC-016` / `EP-025` / `LF-025` / profile `full` / status `required`.
- `WM-FEAT-0075` soundscape studio - `SPEC-016` / `EP-026` / `LF-026` / profile `full` / status `required`.
- `WM-FEAT-0076` room/area/combat/boss/weather/death/victory audio bindings - `SPEC-016` / `EP-026` / `LF-026` / profile `full` / status `required`.
- `WM-FEAT-0077` local/user-owned/signed/licensed assets - `SPEC-016` / `EP-025` / `LF-025` / profile `full` / status `required`.

## Telemetry

- `WM-FEAT-0223` crash-safe bounded ring buffers - `SPEC-019` / `EP-028` / `LF-028` / profile `developer` / status `required`.
- `WM-FEAT-0224` structured event fingerprints and correlation IDs - `SPEC-019` / `EP-028` / `LF-028` / profile `developer` / status `required`.
- `WM-FEAT-0225` severity classification for critical error warning info and debug - `SPEC-019` / `EP-028` / `LF-028` / profile `developer` / status `required`.
- `WM-FEAT-0226` performance regression workflow - `SPEC-019` / `EP-029` / `LF-029` / profile `developer` / status `required`.
- `WM-FEAT-0227` diagnostic deduplication without private content - `SPEC-019` / `EP-028` / `LF-028` / profile `developer` / status `required`.
- `WM-FEAT-0228` root-cause routing by subsystem and priority ring - `SPEC-019` / `EP-029` / `LF-029` / profile `developer` / status `required`.
- `WM-FEAT-0229` bounded autonomous patch planning and validation - `SPEC-019` / `EP-029` / `LF-029` / profile `developer` / status `required`.

## Updates

- `WM-FEAT-0230` signed core app manifests and artifacts - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.
- `WM-FEAT-0231` development canary beta and stable channels - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.
- `WM-FEAT-0232` staged rollout and kill switch metadata - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.
- `WM-FEAT-0233` interrupted download recovery - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.
- `WM-FEAT-0234` failed update startup health and rollback - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.
- `WM-FEAT-0235` separate core provider context command plugin renderer audio model and help lanes - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.
- `WM-FEAT-0236` permission expansion rejection - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.
- `WM-FEAT-0237` migration backup restore and resumability - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.
- `WM-FEAT-0238` active-session update deferral - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.
- `WM-FEAT-0239` maintainer-controlled emergency patch workflow - `SPEC-020` / `EP-035` / `LF-035` / profile `release` / status `required`.
- `WM-FEAT-0240` Local Only Lockdown blocks remote update and asset checks - `SPEC-020` / `EP-034` / `LF-034` / profile `release` / status `required`.

## Voice

- `WM-FEAT-0057` real-time conversational Voice Companion - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0058` push-to-talk and hold-to-talk - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0059` optional wake phrase after opt-in - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0060` local-first STT/TTS - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0061` opt-in remote voice providers - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0062` voice macros - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0063` spoken room/map/quest/combat/setup summaries - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0064` per-character voice profiles - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0065` per-agent voice styles for copilot, mapper, quest, safety, narrator, renderer, and help agents - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0066` barge-in/cancel - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0067` subtitles/transcript controls - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0068` accessibility spoken mode - `SPEC-015` / `EP-024` / `LF-024` / profile `full` / status `required`.
- `WM-FEAT-0211` spoken help and setup summaries - `SPEC-015` / `EP-024` / `LF-024` / profile `immersion` / status `required`.
- `WM-FEAT-0212` different voice styles for copilot mapper quest safety narrator renderer and help agents - `SPEC-015` / `EP-024` / `LF-024` / profile `immersion` / status `required`.

