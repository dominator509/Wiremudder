# SPEC-000: Product Scope and Release Profiles

## Status

Accepted blueprint specification.

## Goal

Define WireMudder as a local-first Mudlet-derived client, preserve the complete inherited classic-client surface, include every accepted WireMudder feature, and separate core, AI, immersion, developer, and full release profiles without misrepresenting disabled optional providers.

## Canonical Terms

WireMudder, Mudlet-derived foundation, Core Classic profile, AI Companion profile, Immersion profile, Developer profile, Full profile, feature certification.

## Required Behavior

WM-SPEC-000-R01: WireMudder starts from a pinned, attribution-preserving Mudlet fork and does not require a complete rewrite before first release.

WM-SPEC-000-R02: Every feature in .agent/features/FEATURES.tsv has one owning specification, one owning graph node, and one verification route.

WM-SPEC-000-R03: The Core Classic profile preserves connection, terminal, scripting, automation, mapping, profile, package, and accessibility behavior inherited from Mudlet.

WM-SPEC-000-R04: The AI Companion profile adds local-first memory, context distillation, provider routing, copilot, explanation, and guarded action capabilities without entering the manual gameplay path.

WM-SPEC-000-R05: The Immersion profile adds voice, renderer, visual emits, and soundscapes as optional degradable systems.

WM-SPEC-000-R06: The Developer profile adds headless operation, replay, Compatibility Lab, Protocol Museum, diagnostics, package tooling, and bug automation.

WM-SPEC-000-R07: The Full profile includes every required feature whose dependencies can be certified; unavailable external providers remain visibly disabled and unadvertised.

WM-SPEC-000-R08: No document, UI, release note, or feature flag may claim implementation or certification without machine-readable evidence.

WM-SPEC-000-R09: User-owned data is exportable and no production cloud dependency is required for the core release.

WM-SPEC-000-R10: Auto-deployment is disabled by default and release signing remains maintainer-controlled.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Explicit consent is required for remote-capable, automated, microphone, package, telemetry, and update behavior.

## Performance

- The Core Classic profile is releasable with every optional P2-P4 subsystem disabled.

## Non-Goals

- A greenfield reimplementation of all Mudlet functionality
- Hidden automation
- A mandatory hosted account
- Claiming optional adapters as working before certification

## Required Tests

- Feature coverage gate
- Release-profile capability matrix
- Full live-fire catalog
- Final ship gate

## Acceptance

All requirements for SPEC-000 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-000, EP-001, EP-038, EP-039. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
