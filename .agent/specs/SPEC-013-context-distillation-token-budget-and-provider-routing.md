# SPEC-013: Context Distillation, Token Budget, and Provider Routing

## Status

Accepted blueprint specification.

## Goal

Create compact cited state capsules, enforce privacy and budgets, route between local and approved remote models, and make cost, latency, quality, and fallback visible.

## Canonical Terms

Context Capsule, AI Provider Router, Token Budget, provider adapter, privacy route, model health.

## Required Behavior

WM-SPEC-013-R01: Deterministic parsers produce typed events first; AI extraction is a bounded second pass only when rules cannot resolve required state.

WM-SPEC-013-R02: Context capsules preserve current room, exits, entities, combat, health, prompt, quest clues, command policy, memory citations, safety evidence, and user request while removing repetitive spam.

WM-SPEC-013-R03: Private messages, credentials, login commands, routing secrets, and unapproved voice content are redacted before any provider sees the request.

WM-SPEC-013-R04: Provider adapters expose one versioned interface for local and remote models and normalize streaming, cancellation, usage, errors, health, and capability metadata.

WM-SPEC-013-R05: Routing considers task, complexity, privacy, risk, latency, cost, locality, availability, historical evaluation, context size, and user policy.

WM-SPEC-013-R06: Slow, failed, unavailable, or budget-exceeded providers degrade to a smaller local route, a user-visible no-suggestion result, or a stronger approved route according to policy; gameplay never waits.

WM-SPEC-013-R07: Token Budget Dashboard records provider, model family, feature, context tokens, output tokens, estimated cost, latency, cache status when available, reason, and profile scope.

WM-SPEC-013-R08: Remote calls require the active privacy mode and explicit provider configuration; no silent remote fallback exists.

WM-SPEC-013-R09: AI output is untrusted data and passes schema, citation, policy, and command-safety validation before use.

WM-SPEC-013-R10: Evaluation fixtures compare quality, privacy leakage, latency, cancellation, cost, and fallback behavior before provider certification.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Provider keys remain in the Secrets Vault and provider requests are purpose-limited.

## Performance

- Context distillation reduces cost and load and never adds synchronous P0 work.

## Non-Goals

- Raw transcript dumping by default
- One model for every task
- Provider output as authorization

## Required Tests

- Capsule snapshot tests
- Redaction adversarial set
- Provider failure
- Budget cap
- Cancellation
- Routing table evaluation

## Acceptance

All requirements for SPEC-013 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-015, EP-016, EP-017, EP-020, EP-021. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
