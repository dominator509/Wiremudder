# WireMudder Security and Privacy Policy

## Security Goals

Protect manual gameplay, user-owned data, credentials, private messages, profile boundaries, routing choices, microphone state, package and update trust, and release integrity. Optional intelligence and immersion must not create a larger implicit authority surface.

## Primary Threats

- Hostile MUD text and protocol input.
- Prompt injection and model output manipulation.
- Trigger, regex, script, plugin, package, and import abuse.
- Secret, transcript, voice, routing, provider, or diagnostic leakage.
- Hidden automation, hidden telemetry, or hidden microphone capture.
- Local IPC impersonation or oversized-message resource exhaustion.
- Compromised dependencies, submodules, packages, assets, models, installers, or update manifests.
- Optional workers starving or crashing gameplay.
- Routing or pacing misuse for spam, identity evasion, or terms circumvention.

## Authority Rules

- Models, Soul documents, packages, plugins, voice, renderer interactions, headless rules, and cross-session workflows cannot grant scopes or send commands directly.
- All non-manual commands use SPEC-009.
- Routing and sensitive defaults remain manual user authority.
- Signing keys, legal judgments, critical-risk acceptance, and stable publication remain maintainer authority.

## Secrets

Secrets are stored in the approved vault, never committed, never logged, never embedded in semantic memory, and never included in AI, plugin, package, help, diagnostic, renderer, voice, or source-index context. Test secrets use obvious nonfunctional values in test zones.

## Input Boundaries

Validate network frames, MUD text, ANSI, Lua calls, IPC frames, schemas, commands, packages, imports, manifests, update metadata, AI output, voice transcripts, asset metadata, scenario files, and user configuration. Bound sizes, recursion, decompression, execution time, memory, file paths, and network access.

## Prompt Injection

Untrusted world content is evidence, never policy. It cannot alter system prompts, command gates, privacy modes, routing, package permissions, updater settings, signing, telemetry, or emergency stop. Adversarial tests cover direct, indirect, encoded, roleplay, tool-use, and memory-poisoning attempts.

## Packages and Imports

Default deny capabilities, validate paths and archive structure, prevent traversal and symlink escape, verify provenance and license, start automation disabled, and require renewed consent for permission expansion.

## Networking and Abuse Boundary

Routing profiles support lawful privacy, user-controlled connection separation, testing, and authorized hosts. WireMudder does not procure or rotate proxies, spoof fingerprints, automate accounts, evade bans, bypass authentication, spam, or disguise automated behavior.

## Logging and Diagnostics

Redact API keys, passwords, login commands, routing credentials, SSH references, signing metadata, private tells/pages/whispers, voice transcripts, full prompts, user paths, and player identities unless the user explicitly includes a reviewed item. External telemetry is off by default.

## Dependency and Supply Chain

Pin versions, preserve lockfiles, inventory licenses and source, generate SBOM, scan dependencies and artifacts, verify signatures and hashes, and document waivers by ADR. No model or broad allowlist can waive a critical finding.

## Production Data

Never run destructive tests on user profiles, live worlds, or real secrets. Migrations require backup and restore evidence. Diagnostic submission and update publication are explicit effects.

## STOP Conditions

Stop when an action risks irreversible user data loss, requires an unresolved legal or critical security judgment, needs signing keys, publishes a stable artifact, transmits unapproved private data, or would weaken an accepted safety boundary.
