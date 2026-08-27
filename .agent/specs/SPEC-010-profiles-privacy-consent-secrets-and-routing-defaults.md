# SPEC-010: Profiles, Privacy, Consent, Secrets, and Routing Defaults

## Status

Accepted blueprint specification.

## Goal

Provide persistent Character Memory Profiles and strong privacy controls while preventing models and packages from changing sensitive defaults or seeing secrets.

## Canonical Terms

Character Memory Profile, Privacy Firewall, Local Only Lockdown, Secrets Vault, consent receipt, routing default.

## Required Behavior

WM-SPEC-010-R01: Every character tab attaches to one persistent Character Memory Profile with world, memory, routing, AI, voice, renderer, soundscape, automation-pack, Soul, and command-database defaults.

WM-SPEC-010-R02: Sensitive default changes are user-originated and audited; AI and automation cannot change routing, secrets, provider keys, plugin permissions, telemetry, updater, or privacy modes.

WM-SPEC-010-R03: Privacy modes are disabled, local-only, local-preferred, remote-redacted, and remote-approved and their exact egress behavior is testable.

WM-SPEC-010-R04: Local Only Lockdown disables remote AI, remote speech, external asset generation, external telemetry, package downloads, and update checks unless individually and visibly overridden by the user.

WM-SPEC-010-R05: Privacy Firewall shows what data, citations, transcript ranges, redactions, provider, model, token estimate, and purpose apply to each AI request.

WM-SPEC-010-R06: Secrets Vault protects MUD passwords, provider tokens, routing credentials, SSH references, signing metadata, and other authentication material using OS facilities or an evidence-backed encrypted fallback.

WM-SPEC-010-R07: Secrets never enter AI context, logs, scripts, plugins, packages, source indexes, diagnostics, renderer prompts, or voice transcripts.

WM-SPEC-010-R08: Private tells, pages, whispers, and voice content are protected by default and excluded from remote context unless specifically approved.

WM-SPEC-010-R09: Consent receipts are scoped, versioned, revocable, and tied to feature, provider, data class, profile, and time.

WM-SPEC-010-R10: Local data supports export, deletion, backup, restore, retention, and provenance without requiring a cloud account.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- All remote egress passes deterministic policy before provider invocation.

## Performance

- Redaction rules are compiled or cached and cannot stall P0.

## Non-Goals

- Silent remote fallback
- Durable semantic storage of credentials

## Required Tests

- Lockdown network-denial proof
- Secret redaction corpus
- Consent revoke test
- Profile export/restore

## Acceptance

All requirements for SPEC-010 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-006, EP-007, EP-014, EP-016, EP-024, EP-028, EP-034. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
