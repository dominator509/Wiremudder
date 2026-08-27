# SPEC-022: Security, Privacy, Threat Model, and Abuse Boundaries

## Status

Accepted blueprint specification.

## Goal

Protect users from hostile servers, packages, providers, updates, prompt injection, data leakage, hidden automation, and resource exhaustion while preserving legitimate privacy and accessibility.

## Canonical Terms

trust boundary, prompt injection, least privilege, redaction, abuse boundary, threat model.

## Required Behavior

WM-SPEC-022-R01: MUD text, network frames, AI output, voice transcripts, packages, imports, assets, update metadata, and source indexes are untrusted inputs.

WM-SPEC-022-R02: Secrets are stored through the Secrets Vault, never logged, never committed, never placed in AI context, and never exposed to plugins or packages without impossible-by-default capability policy.

WM-SPEC-022-R03: Remote egress is purpose-limited, disclosed, provider-scoped, redacted, and blocked by Local Only Lockdown.

WM-SPEC-022-R04: Prompt injection cannot override command safety, privacy, routing, plugin, update, telemetry, signing, or emergency-stop policy.

WM-SPEC-022-R05: Packages and workers run with least privilege, bounded resources, explicit capability grants, and crash isolation.

WM-SPEC-022-R06: Supply-chain review covers source, dependency, submodule, binary, model, voice, audio, visual, package, installer, and update provenance.

WM-SPEC-022-R07: Network routing supports lawful user-controlled privacy and testing and excludes proxy procurement, identity rotation, fingerprint spoofing, automated account creation, spam, or ban evasion.

WM-SPEC-022-R08: Threat models include data flow, assets, actors, entry points, trust boundaries, misuse cases, mitigations, residual risk, and verification.

WM-SPEC-022-R09: Security-sensitive changes require forced-failure and denial tests and cannot be waived by a model vote.

WM-SPEC-022-R10: Critical findings block release until fixed or explicitly accepted by a human maintainer with documented rationale and scope.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- This specification is binding on every subsystem.

## Performance

- Security controls are deterministic and cached where safe but never skipped for speed.

## Non-Goals

- Offensive automation
- Terms-of-service circumvention
- Hidden monitoring

## Required Tests

- Threat-model review
- Secrets scan
- Prompt injection suite
- Permission denial
- Supply-chain scan
- Resource exhaustion

## Acceptance

All requirements for SPEC-022 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-005, EP-006, EP-008, EP-010, EP-011, EP-016, EP-024, EP-028, EP-030, EP-033. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
