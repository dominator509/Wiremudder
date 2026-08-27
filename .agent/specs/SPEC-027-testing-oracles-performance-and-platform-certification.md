# SPEC-027: Testing, Oracles, Performance, and Platform Certification

## Status

Accepted blueprint specification.

## Goal

Require independent behavioral oracles, deterministic tests, real controlled dependencies, fuzzing, performance evidence, accessibility checks, platform matrices, and no gate weakening.

## Canonical Terms

test double zone, behavioral oracle, live-fire, platform certification, performance fixture, flaky test.

## Required Behavior

WM-SPEC-027-R01: Test zones are explicitly enumerated and no test double appears in production paths.

WM-SPEC-027-R02: Unit tests prove pure policy and transformations; contract tests prove schemas; integration tests use real controlled local dependencies; E2E drives real entry points; live-fire proves user outcomes.

WM-SPEC-027-R03: Mudlet reference runs, protocol standards, controlled fake MUD servers, sanitized package/profile corpora, and explicit WireMudder decisions form independent oracles.

WM-SPEC-027-R04: Tests created by an implementation agent are reviewed against independent fixtures and cannot be the sole oracle for their own assumptions.

WM-SPEC-027-R05: Fuzzing covers protocol, ANSI, IPC, import, package, manifest, command, and schema parsers; property tests cover round trips and invariants.

WM-SPEC-027-R06: Performance tests record hardware, OS, build, workload, repetitions, distributions, thresholds, and raw artifacts.

WM-SPEC-027-R07: Accessibility tests cover keyboard, focus, semantics, contrast or non-color state, reduced motion, subtitles, and raw-text fallback.

WM-SPEC-027-R08: Windows, macOS, and Linux certification uses clean builds, tests, packaging, upgrade, rollback, and smoke evidence.

WM-SPEC-027-R09: A flaky test is a defect and is fixed or removed only by ADR with replacement evidence; retry-until-green is forbidden.

WM-SPEC-027-R10: A gate may be strengthened during a run but cannot be weakened to make code pass.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Adversarial fixtures contain no real user secrets or private data.

## Performance

- Benchmark execution is isolated from interactive sessions.

## Non-Goals

- Mock-only E2E
- Self-authored tests as sole compatibility proof

## Required Tests

- Oracle differential suite
- Fuzz suites
- Performance matrix
- Accessibility suite
- Clean platform builds

## Acceptance

All requirements for SPEC-027 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-003, EP-009, EP-010, EP-011, EP-012, EP-032, EP-033, EP-036, EP-038. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
