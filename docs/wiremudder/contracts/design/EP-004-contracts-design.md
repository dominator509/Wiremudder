# WireMudder Canonical Vocabulary — design (EP-004)

## Purpose

SPEC-003 requires a canonical vocabulary for events, capabilities,
errors, privacy classes, profiles, commands, memory, telemetry,
packages, updates, voice, renderer, and headless surfaces. Every schema
lives under `schemas/wiremudder/` with a stable `$id` and version.

## Schemas

- `schemas/wiremudder/replay/session-replay.schema.json` (EP-003)
- `schemas/wiremudder/telemetry/event.schema.json` — local telemetry
  events: subsystem, severity, fingerprint, correlation, priority,
  latency, queue, drop, coalesce, provider, feature.
- `schemas/wiremudder/capability/capability.schema.json` — capability
  states (uncertified/implemented/certified/disabled) with owner node.
- `schemas/wiremudder/error/error.schema.json` — typed errors per
  SPEC-025 (validation, consent, policy, authorization, unavailable,
  timeout, cancellation, conflict, security, compatibility,
  verification, rollback, resource_exhaustion, internal).
- `schemas/wiremudder/privacy/privacy.schema.json` — privacy classes
  (public/local/private/sensitive/secret), redaction, export policy.
- `schemas/wiremudder/profile/profile.schema.json` — local-first profile
  metadata.

## Bindings

`tools/schema-bindings/generate_bindings.py` validates every schema and
writes `tools/schema-bindings/bindings.manifest.json` consumed by later
nodes (EP-004 M3, EP-022+). The manifest lists path, `$id`, title, and
version for each canonical schema.

## Traceability Gates

- `scripts/feature-coverage-check.sh` — every WM-FEAT has an owner node
  and test path (WM-FEAT-0151).
- `scripts/spec-trace-check.sh` — every requirement is traced to a
  validating test (WM-FEAT-0152).
- `scripts/expected-files-audit.sh` + `scope-audit.sh` — scope fence with
  evidence-backed amendments (WM-FEAT-0153).

## Invariants

- Every schema: `$id` under https://wiremudder.dev/schemas/, title, type
  object, and a version const where versioned.
- Enums are closed (no free-form severity/state/code/classification).
- Bindings manifest is regenerated whenever a schema changes.
