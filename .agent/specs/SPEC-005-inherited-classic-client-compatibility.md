# SPEC-005: Inherited Classic Client Compatibility

## Status

Accepted blueprint specification.

## Goal

Preserve and verify the mature Mudlet behavior that prevents WireMudder from being rebuilt from scratch, while allowing explicitly documented WireMudder extensions.

## Canonical Terms

reference behavior, behavioral parity, compatibility level, differential fixture, inherited feature.

## Required Behavior

WM-SPEC-005-R01: The baseline build connects to a controlled MUD server, renders text, accepts manual commands, saves and reloads a profile, runs Lua, fires a trigger, imports a package, and exercises the mapper.

WM-SPEC-005-R02: Terminal, ANSI/xterm/truecolor, scrollback, selection, copy, search, command history, logging, and transcript behavior remain available.

WM-SPEC-005-R03: Aliases, triggers, timers, macros, hotkeys, variables, speedwalking, throttling, command-input triggers, gag, highlight, substitute, multi-state triggers, and wizards remain available.

WM-SPEC-005-R04: Spellcheck, autocorrect, tab completion, entity completion, and command-template completion remain available where supported by the inherited baseline.

WM-SPEC-005-R05: Capture panes, status bars, gauges, dashboards, layouts, themes, command palette, profile management, and multiple tabs/windows remain available.

WM-SPEC-005-R06: Lua 5.1 behavior and existing package/profile expectations are treated as compatibility contracts, not reimplemented from prose.

WM-SPEC-005-R07: Mapper rooms, zones, coordinates, custom, hidden, locked, one-way and portal exits, weights, speedwalk routing, labels, and import/export receive reference fixtures.

WM-SPEC-005-R08: Every intentional incompatibility has a user-visible migration, rationale, fixture, ADR, and release note.

WM-SPEC-005-R09: Imported automation starts disabled or confirmation-gated when WireMudder cannot prove existing trust state.

WM-SPEC-005-R10: No parity claim is accepted from compilation alone; observable reference and WireMudder traces must agree under the declared compatibility level.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Reference fixtures are sanitized and contain no user passwords, private messages, or private profiles.

## Performance

- Compatibility additions must preserve the inherited hot-path baseline within declared thresholds.

## Non-Goals

- Byte-for-byte UI identity when WireMudder intentionally adds controls
- Copying undocumented implementation structure into Rust

## Required Tests

- Reference profile smoke
- Lua compatibility corpus
- Automation order fixtures
- Mapper round trip
- UI state-model tests

## Acceptance

All requirements for SPEC-005 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-001, EP-003, EP-009, EP-010, EP-012, EP-013, EP-030, EP-036. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
