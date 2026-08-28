# WireMudder User Documentation

This is the user guide for WireMudder, a local-first Mudlet-derived MUD
client. It documents every enabled feature in the product, how to use it,
what it may access, and how to keep your data safe. The documentation is
versioned with the application and every claim is backed by machine-readable
evidence (SPEC-000-R08).

## Quick Start

1. Connect to a MUD world using the profile chooser.
2. Type commands in the input line at the bottom of the terminal pane.
3. Add aliases, triggers, and timers from the automation toolbar to
   reduce repetitive typing.
4. Install a package from a `.mpackage` archive or a directory with a
   manifest. Review the requested permissions before approving.
5. Your data stays on your machine. No hosted account is required for the
   core release (SPEC-000-R09).

## Documentation Sections

- [Terminal](terminal.md) — the terminal pane, colors, scrollback, and history.
- [Automation](automation.md) — aliases, triggers, timers, macros, and scripting.
- [Packages](packages.md) — installing, updating, and removing packages.
- [Imports](imports.md) — migrating from other clients.
- [Mapper](mapper.md) — mapping rooms, exits, and areas.
- [Profiles](profiles.md) — profiles, worlds, and settings.
- [Sessions](sessions.md) — multiple sessions, multi-play, and routing.
- [Voice](voice.md) — voice companion and voice macros.
- [Renderer and Soundscapes](renderer.md) — retro renderer, emits, and audio.
- [AI and Memory](ai.md) — local-first memory, context, and the AI companion.
- [Help](help.md) — help bubbles, Setup Coach, and Ask WireMudder AI.
- [Privacy](privacy.md) — what the client stores and sends.
- [Security](security.md) — permissions, secrets, and command safety.
- [Updates](updates.md) — how updates work and how to roll back.
- [Telemetry and Diagnostics](telemetry.md) — logs, metrics, and support bundles.
- [Headless](headless.md) — headless operation, replay, and the API.
- [Performance](performance.md) — budgets, degradation, and tuning.
- [Accessibility](accessibility.md) — accessibility features.
- [Troubleshooting](troubleshooting.md) — common problems and fixes.
- [Operations](operations.md) — backup, restore, and incident runbooks.
- [Governance](governance.md) — contribution, licensing, and upstream sync.
- [Feature Index](feature-index.md) — every enabled feature and where it is documented.

## Honest Labels

- **Enabled** — implemented, tested, and documented.
- **Optional** — present but requires explicit configuration or a provider.
- **Disabled** — present in the build but off until certified.
- **Research** — under study; no implementation claim is made.

Unsupported and research features are labeled honestly throughout this
guide. If a page says a capability is not certified, that is the truth.
