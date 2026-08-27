# SPEC-007: Desktop, Terminal, Workspace, and Accessibility

## Status

Accepted blueprint specification.

## Goal

Extend the inherited Qt desktop with WireMudder surfaces while preserving terminal performance, keyboard operation, accessibility, layouts, and text-only fallback.

## Canonical Terms

Qt desktop, terminal, workspace, dock, capture pane, accessibility tree, text-only fallback.

## Required Behavior

WM-SPEC-007-R01: The initial desktop remains Qt-based and follows verified Mudlet UI, model-view, signal-slot, translation, ownership, and naming conventions.

WM-SPEC-007-R02: WireMudder surfaces include Trust Center, Privacy Firewall, token budget, AI suggestions, memory, quest, tactical, voice, renderer, soundscape, diagnostics, help, and supervisor views where their owning nodes are enabled.

WM-SPEC-007-R03: Raw terminal text is always visible and cannot be hidden or delayed by renderer or AI surfaces.

WM-SPEC-007-R04: Workspace layouts, tabs, windows, capture panes, gauges, dashboards, themes, command palette, and per-profile persistence remain functional.

WM-SPEC-007-R05: Keyboard-only operation, visible focus, screen-reader labels, non-color-only state, large-text resilience, reduced-motion, no-animation, subtitles, and raw-text mode are required.

WM-SPEC-007-R06: Server-provided text cannot create trusted UI controls or render unescaped HTML in privileged surfaces.

WM-SPEC-007-R07: High-frequency updates are batched and measured; no optional dock performs per-line blocking work.

WM-SPEC-007-R08: Loading, empty, degraded, disconnected, sidecar-unavailable, permission-denied, and error states are explicit.

WM-SPEC-007-R09: Destructive or privacy-sensitive actions disclose effect, scope, source, and confirmation status.

WM-SPEC-007-R10: Localization follows existing Mudlet translation conventions and new strings include translator context where needed.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Untrusted MUD content is visually and structurally separated from trusted client controls.

## Performance

- UI additions cannot cause per-line cross-process or model calls.

## Non-Goals

- A separate React/Tauri shell for the first release
- Renderer-only gameplay

## Required Tests

- Qt UI integration tests
- Keyboard traversal
- Accessibility tree snapshot
- Terminal flood with all docks enabled

## Acceptance

All requirements for SPEC-007 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-009, EP-012, EP-024, EP-025, EP-027, EP-031. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
