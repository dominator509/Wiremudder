# ADR-0015: Keep Inherited Replacements Reversible

## Status

Accepted

## Context

The first-generation blueprint relied on a greenfield interpretation and did not have complete Graphlock evidence, feature traceability, or compatibility gates. WireMudder must preserve mature inherited behavior while enabling isolated new systems.

## Decision

Any strangler replacement retains the old implementation through at least one stable release.

## Consequences

- The active graph and specifications implement this decision.
- A contrary change requires a superseding ADR, source evidence, feature and requirement trace updates, graph compatibility review, tests, rollback, and explicit maintainer approval where security, licensing, or release authority is involved.
- Existing green tags remain immutable history.

## Verification

`sh scripts/validate-blueprint.sh`, the owning node verifier, applicable live-fire proof, expected-file audit, and final release gates.
