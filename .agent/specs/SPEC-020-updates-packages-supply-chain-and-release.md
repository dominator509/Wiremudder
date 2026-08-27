# SPEC-020: Updates, Packages, Supply Chain, and Release

## Status

Accepted blueprint specification.

## Goal

Provide signed, provenance-aware, rollback-capable release and asset lanes with staged rollout, permission checks, migration safety, and maintainer-controlled signing.

## Canonical Terms

signed manifest, release channel, update lane, staged rollout, rollback manifest, SBOM, provenance.

## Required Behavior

WM-SPEC-020-R01: Release channels are development, canary, beta, and stable and users select their channel.

WM-SPEC-020-R02: Core app, provider adapter, context rules, command pack, plugin pack, renderer pack, audio pack, local model asset, and help index are separate update lanes.

WM-SPEC-020-R03: Stable artifacts and manifests are signed, hashed, provenance-recorded, reproducible where practical, and accompanied by SBOM and license inventory.

WM-SPEC-020-R04: The updater rejects unsigned, invalid, corrupted, unexpected downgrade, incompatible, or permission-expanding artifacts.

WM-SPEC-020-R05: Interrupted download is resumable and failed install restores the previous healthy version.

WM-SPEC-020-R06: An update is healthy only after clean startup and required smoke checks; crash loops trigger local quarantine and rollback guidance.

WM-SPEC-020-R07: Updates and migrations defer during active sessions unless the user explicitly stops sessions and approves.

WM-SPEC-020-R08: Package, model, audio, renderer, help, and provider assets are optional and never silently bundled or enabled.

WM-SPEC-020-R09: Autonomous agents may prepare artifacts and recommendations but cannot access signing keys or publish stable releases.

WM-SPEC-020-R10: Release, migration, rollback, channel switching, permission expansion, signature failure, and active-session deferral receive live-fire proofs.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Signing keys are hardware-backed or maintainer-controlled and absent from agent environments.

## Performance

- Update, indexing, download, and migration work is P4 and cannot block active gameplay.

## Non-Goals

- Agent-controlled signing keys
- Silent model downloads
- Permission expansion on update

## Required Tests

- Signature rejection
- Hash mismatch
- Interrupted download
- Rollback drill
- Migration restore
- Channel switch

## Acceptance

All requirements for SPEC-020 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-010, EP-030, EP-033, EP-034, EP-035, EP-038, EP-039. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
