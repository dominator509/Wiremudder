# WireMudder Project Brief

## Mission

WireMudder is a local-first, open-source desktop and headless client for MUDs, MUSHes, MOOs, MUCKs, and adjacent text worlds. It begins as an evidence-pinned Mudlet fork so users inherit a mature Qt desktop, terminal, Lua scripting, automation, mapper, profiles, packages, protocols, and cross-platform release foundation. It then adds an isolated Rust WireCore for AI, memory, privacy, command safety, voice, rendering, soundscapes, replay, diagnostics, headless supervision, safe updates, and future bounded bug remediation.

## Product Promise

Raw text, manual input, connection health, command sending, and emergency stop are sacred. Optional systems are asynchronous, budgeted, cancelable, visible, consented, and degradable. WireMudder remains useful when WireCore, AI, voice, renderer, sound, telemetry, packages, source indexing, and remote services are disabled.

## Target Users

- Classic players needing low-latency terminal, scrollback, history, aliases, triggers, timers, macros, speedwalking, logs, panes, gauges, themes, packages, protocols, and mapping.
- Roleplayers and long-running characters needing Character Memory Profiles, Soul documents, World Brain, World Bible, Quest Compass, Tactical HUD, explanations, privacy-scoped assistance, and per-character defaults.
- Power users needing scripting, debugging, package permissions, imports, multiple sessions, routing profiles, command safety, replay, and diagnostics.
- Accessibility users needing keyboard operation, raw text, screen-reader semantics, spoken feedback, subtitles, reduced motion, and text-only fallback.
- Developers and maintainers needing headless sessions, JSONL, scenarios, Protocol Museum, Compatibility Lab, performance fixtures, signed packages, upstream sync, and Graphlock automation.

## Core Outcomes

1. Build and run the pinned inherited client without a WireMudder rewrite.
2. Preserve and prove the complete classic-client feature surface.
3. Add WireCore without blocking or crashing text gameplay.
4. Give each character persistent, exportable, privacy-scoped defaults and memory.
5. Offer local-first AI suggestions, explanations, and guarded actions with visible context, cost, confidence, and command safety.
6. Add optional voice, retro visuals, emits, and soundscapes that shed load before text is affected.
7. Support desktop and headless multi-session operation with a global emergency stop.
8. Provide safe package, script, import, update, diagnostics, and bug-remediation ecosystems.
9. Ship only evidence-certified features and platforms.

## Release Profiles

| Profile | Purpose | Required Capability Boundary |
| --- | --- | --- |
| Core Classic | Useful first release | Inherited client, Graphlock, compatibility, privacy baseline, profiles, command safety, storage, core accessibility, diagnostics. |
| AI Companion | Optional intelligence | Core plus context distillation, provider routing, Copilot, Soul, agents, guarded actions, World Brain, quest and tactical assistance. |
| Immersion | Optional audio and visual layer | AI Companion plus voice, renderer, emits, and soundscapes with text fallback. |
| Developer | Power and maintenance tools | Core plus headless, replay, Protocol Museum, Compatibility Lab, AI Debugger, imports, package tooling, and bug automation. |
| Full | Complete WireMudder product | All required features with uncertified external adapters visibly disabled. |

## Business and Licensing Direction

WireMudder remains open source and attribution-preserving. The exact inherited and combined-work license obligations are verified in EP-000 and EP-002. Monetization can focus on lawful hosted services, support, deployment, licensed assets, or community services without hiding source obligations or taking user data ownership.

## Success Metrics

The initial target goals are manual input under 5 ms app-side, outbound queue under 10 ms, terminal append under 10 ms, emergency stop under 10 ms, measured renderer work within 4-6 ms when enabled, bounded optional queues, no secret leakage, telemetry off by default, export and restore success, and no P0/P1 regression against the inherited baseline. These are targets until benchmark evidence is recorded.

## Status

This pack is a complete blueprint and governance system. It is not a claim that WireMudder runtime features have been implemented.
