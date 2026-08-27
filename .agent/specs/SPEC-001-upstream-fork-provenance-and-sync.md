# SPEC-001: Upstream Fork, Provenance, and Synchronization

## Status

Accepted blueprint specification.

## Goal

Preserve Mudlet history and licensing, pin an evidence-backed upstream baseline, minimize divergence, and make every upstream synchronization reproducible and reversible.

## Canonical Terms

upstream, origin, upstream baseline, patch classification, sync branch, provenance record, GPL compliance.

## Required Behavior

WM-SPEC-001-R01: The repository retains Mudlet Git history and configures the official repository as the upstream remote.

WM-SPEC-001-R02: UPSTREAM.lock.yaml records repository URL, branch, commit, stable release reference, evidence date, and source-document hashes.

WM-SPEC-001-R03: EP-000 verifies the locked commit, license files, submodules, build instructions, agent instructions, and current source layout before edits.

WM-SPEC-001-R04: WireMudder changes are classified as upstreamable, bridge, feature, branding, security hardening, or Graphlock governance.

WM-SPEC-001-R05: Generic fixes are prepared for upstream contribution when practical, while WireMudder-specific behavior remains namespaced.

WM-SPEC-001-R06: Upstream sync occurs on a dedicated branch and runs compatibility, security, and performance gates before merge.

WM-SPEC-001-R07: No mass source move, class rename, or namespace rewrite is permitted merely for branding.

WM-SPEC-001-R08: Submodule, package, generated-file, and binary-asset provenance is inventoried and license-gated.

WM-SPEC-001-R09: Every accepted upstream sync records before and after SHAs and rollback instructions.

WM-SPEC-001-R10: A failed sync leaves the previous green tag intact and cannot be promoted.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Signing keys and upstream credentials are not exposed to coding agents.

## Performance

- Upstream sync must not introduce a P0 or P1 regression.

## Non-Goals

- Rebasing away upstream history
- Copying source into an unrelated empty repository
- Silently changing inherited licensing

## Required Tests

- Upstream lock verification
- Sync rehearsal
- License inventory
- Compatibility regression suite

## Acceptance

All requirements for SPEC-001 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-000, EP-001, EP-002, EP-033, EP-036. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
