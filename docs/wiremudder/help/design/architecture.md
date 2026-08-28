# Contextual Help, Setup Coach, and Source Index — Design (EP-027)

## Overview

EP-027 adds an optional contextual help layer to WireMudder: help
bubbles with safe defaults/validation/privacy guidance, a local Help
Knowledge Index, an Ask WireMudder AI handoff, world capability
onboarding, CLI parity, and opt-in source checkout indexing
(SPEC-018). The Setup Coach may explain and propose steps but has no
mutation authority (SPEC-018-R06).

## Architecture

- `wirecore/crates/wire-help/` — deterministic core engine
  (`HelpEngine`): Help Knowledge Index (reproducible, 6 source kinds),
  field help bubbles, scoped sanitized Ask context, help modes,
  propose-only Setup Coach, opt-in source index, evidence-based
  capability probes, CLI/UI parity, app versioning.
- `schemas/wiremudder/help/` — index-entry, field-help, ask-context,
  coach-step, source-index-state v1 schemas.
- `tools/help-indexer/` — real Rust CLI that reproducibly generates the
  index from accepted docs, schemas, command catalog, ADRs, and
  sanitized source references (identical runs produce identical output).
- `src/wiremudder/ui/help/help_boundary.{h,cpp}` — passive model-side
  Qt6 boundary compiled into the Mudlet-derived client (authorized by
  discovered amendment WM-SRC-000183 for `src/CMakeLists.txt`).

## Data Scope and Privacy

The engine stores index entries (sanitized bodies), field help text,
coach steps, capability probes, and source-index state. Secrets are
redacted deterministically before any AI handoff or indexing; source
indexing is opt-in, local-first, idle-only, and secret-aware
(WM-SPEC-018-R05). Help modes are local-only and remote-redacted or
disabled according to privacy policy (WM-SPEC-018-R03). No remote
egress exists.

## Action Authority

The help boundary is passive (`isPassive() = true`,
`canSendCommand() = false`, `canChangeSettings() = false`). The coach
records propose requests only; `apply_step` is hard-denied
(DeniedPolicy). There is no mutation path (SPEC-018-R06).

## Audit and Health

The engine keeps a bounded audit trail (MAX_AUDIT=1024) and exposes
index state hash, entry count, source-index counters, and help mode.
Health = engine ready in local-only or remote-redacted mode; readiness
= index contains at least one entry from an accepted source.

## Restart Behavior

The engine is pure state. The index regenerates reproducibly via
`help-indexer` from accepted sources; source indexing resumes from a
checkpoint (resumable). Help requests never block settings interaction
or gameplay (WM-SPEC-018-R10); lookups are O(log n) over the index.

## Fallback

Ship static local help and field-level documentation links without AI
or source indexing (node contract fallback). In Disabled mode all help
answers deny.

## Rollback

`git checkout -- src/CMakeLists.txt` removes the boundary from the
client build (discovered amendment rollback). The crate, schemas, and
tool are additive and reversible by deletion.
