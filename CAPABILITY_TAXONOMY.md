# WireMudder Capability Taxonomy

## Classes

- Observation: read current approved state with no effect.
- Suggestion: return advice, explanation, summary, or candidate data with no effect.
- Action Proposal: request a bounded effect through command safety or another deterministic gateway.
- Workflow: durable multi-step objective with policy, cancellation, compensation, and audit.
- Stream: versioned events with ordering, backpressure, and cancellation.
- Administrative: profile, privacy, permission, secret, routing, provider, package, update, or release configuration and therefore user or maintainer controlled.

## Descriptor Fields

Stable ID, semantic version, class, description, input and output schema, allowed principals, profile and world scope, privacy class, risk tier, approval policy, reversibility, idempotency, timeout, cancellation, queue priority, resource budget, network access, secret access, storage access, provider requirements, health, certification, release profile, events, and rollback.

## Certification States

Declared, implemented, tested, live-fire-certified, disabled, and blocked. State changes require evidence and cannot be inferred from compilation.
