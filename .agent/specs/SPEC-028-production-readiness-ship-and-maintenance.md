# SPEC-028: Production Readiness, Ship, and Maintenance

## Status

Accepted blueprint specification.

## Goal

Define evidence-backed release, rollback, maintenance, incident, support, upstream sync, and post-release health gates for the complete product.

## Canonical Terms

ship gate, release candidate, green tag, rollback drill, maintenance graph, known risk.

## Required Behavior

WM-SPEC-028-R01: A release candidate is created only after every required node for its release profile is DONE with evidence, node verify, expected-files audit, ledger event, and green tag.

WM-SPEC-028-R02: The fresh final verify runs blueprint, build, format, lint, type, unit, integration, E2E, security, dependency, reality, smoke, live-fire, feature coverage, spec trace, performance, accessibility, license, and platform gates applicable to the profile.

WM-SPEC-028-R03: Known critical defects, security findings, P0/P1 regressions, data-loss risks, secret leakage, signature failures, or emergency-stop failures block release.

WM-SPEC-028-R04: Install, upgrade, downgrade policy, backup, restore, migration, rollback, failed-update recovery, and uninstall are documented and drilled.

WM-SPEC-028-R05: Artifacts include source, binary, checksums, signatures, SBOM, provenance, license notices, release notes, compatibility matrix, known risks, and support instructions.

WM-SPEC-028-R06: Production is not automatically deployed or published because AUTO_DEPLOY is false; the pack emits exact manual signing and publish steps without exposing keys.

WM-SPEC-028-R07: Post-release monitoring uses opt-in health signals and maintainer review and can pause rollout or revoke an update manifest.

WM-SPEC-028-R08: Maintenance changes use the same Graphlock contracts, expected-file fences, tests, evidence, and rollback as initial development.

WM-SPEC-028-R09: Upstream sync is rehearsed before every stable release and generic fixes are assessed for contribution.

WM-SPEC-028-R10: RUN_COMPLETE is appended only after the release tag and all observed gate sentinels are recorded.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Maintainer-controlled keys and human legal/security decisions remain outside autonomous execution.

## Performance

- No release may regress P0/P1 beyond accepted measured thresholds.

## Non-Goals

- Automatic stable publication by a coding agent
- Documentation-only production readiness

## Required Tests

- Fresh ship gate
- Installer matrix
- Rollback drill
- Artifact verification
- Release-profile capability audit

## Acceptance

All requirements for SPEC-028 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-033, EP-034, EP-035, EP-036, EP-037, EP-038, EP-039. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
