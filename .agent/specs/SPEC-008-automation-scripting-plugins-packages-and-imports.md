# SPEC-008: Automation, Scripting, Plugins, Packages, and Imports

## Status

Accepted blueprint specification.

## Goal

Preserve Lua and classic automation while adding budgets, debugging, package permissions, provenance, compatibility importers, and safe ecosystem tooling.

## Canonical Terms

Lua 5.1, script runtime, plugin, package, world pack, permission manifest, importer.

## Required Behavior

WM-SPEC-008-R01: Existing Lua 5.1 profile behavior remains the primary scripting compatibility surface until an explicit replacement passes the full corpus.

WM-SPEC-008-R02: Scripts, triggers, aliases, timers, macros, key bindings, and packages run with measured budgets and slow-offender diagnostics.

WM-SPEC-008-R03: A plugin or package declares version, provenance, license, content hash, requested permissions, update policy, and supported WireMudder/Mudlet versions.

WM-SPEC-008-R04: Permissions cover filesystem, network, microphone, AI egress, secrets, routing, updater, telemetry, UI, command send, memory, renderer, and audio access and default deny.

WM-SPEC-008-R05: Package updates cannot silently expand permissions and require renewed approval for any increase.

WM-SPEC-008-R06: Imported automation starts disabled or confirmation-gated and displays a migration report.

WM-SPEC-008-R07: Script editor, syntax checking, debug console, variable inspector, event replay, Macro Forge, and Trigger Test Lab are included in the graph.

WM-SPEC-008-R08: World packs, command packs, trigger/macro packs, themes, renderer packs, soundscape packs, Soul templates, and help indexes use signed or user-local provenance-aware manifests.

WM-SPEC-008-R09: Mudlet, MUSHclient, TinTin++, zMUD/CMUD concepts, and generic JSON, CSV, and YAML import paths have separate compatibility and legal review tracks.

WM-SPEC-008-R10: A plugin crash cannot terminate an active session and a runaway hook is quarantined.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Package extraction prevents traversal, symlink escape, oversized files, and executable surprise.

## Performance

- Package checks and indexing are P4 and pause during active play.

## Non-Goals

- Executing untrusted imports automatically
- Global unrestricted plugin access

## Required Tests

- Lua corpus
- Permission denial tests
- Malicious package fixture
- Importer round trip
- Slow-hook quarantine

## Acceptance

All requirements for SPEC-008 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-009, EP-010, EP-022, EP-030, EP-033, EP-037. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
