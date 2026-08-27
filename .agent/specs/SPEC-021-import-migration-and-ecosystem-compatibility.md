# SPEC-021: Import, Migration, and Ecosystem Compatibility

## Status

Accepted blueprint specification.

## Goal

Migrate users and ecosystem assets safely from Mudlet and other power clients with provenance, disabled automation, deterministic reports, and reversible backups.

## Canonical Terms

import plan, migration report, disabled automation, source format, round trip.

## Required Behavior

WM-SPEC-021-R01: Mudlet profile, package, module, map, script, trigger, alias, timer, macro, layout, theme, and related formats are discovered from the pinned source and fixtures rather than guessed.

WM-SPEC-021-R02: MUSHclient, TinTin++, zMUD/CMUD concepts, and generic JSON, CSV, and YAML receive separate legal, format, and compatibility research records.

WM-SPEC-021-R03: Every import creates a source hash, format version, provenance record, backup, normalized result, warning list, unsupported-item list, and rollback path.

WM-SPEC-021-R04: Imported automation, network access, package permissions, AI access, routing references, microphone access, and external calls start disabled until reviewed.

WM-SPEC-021-R05: Unknown fields are preserved where safe or reported; they are never silently discarded when loss would matter.

WM-SPEC-021-R06: Duplicate identities, rooms, hashes, variables, package IDs, and settings use deterministic conflict policy and user-visible resolution.

WM-SPEC-021-R07: Importers are streaming and size-bounded and prevent traversal, entity expansion, decompression bombs, and executable surprise.

WM-SPEC-021-R08: Representative corpus fixtures cover clean, old, malformed, partially corrupt, conflicting, oversized, and adversarial inputs.

WM-SPEC-021-R09: A failed import leaves the original and destination unchanged except for a removable diagnostic report.

WM-SPEC-021-R10: Migration documentation distinguishes equivalent, transformed, unsupported, and intentionally rejected behavior.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Import runs in a constrained parser boundary and does not access secrets or the network.

## Performance

- Large imports are cancellable, resumable where practical, and never run in the gameplay path.

## Non-Goals

- Executing imported automation
- Claiming undocumented proprietary-format parity

## Required Tests

- Mudlet profile round trip
- Package/map corpus
- Conflict tests
- Malformed archive
- Rollback

## Acceptance

All requirements for SPEC-021 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-003, EP-009, EP-010, EP-013, EP-030, EP-036. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
