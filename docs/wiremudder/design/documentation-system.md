# Documentation, Package Developer, and Community Ecosystem — Design (EP-037)

## Purpose

Complete the user, administrator, package author, importer, accessibility,
privacy, troubleshooting, headless, API, build, contribution, upstream,
release, and support documentation with examples that match tested
contracts.

## Documentation Model

WireMudder documentation is organized by audience and versioned with the
application (SPEC-018-R09):

- `docs/wiremudder/user/` — end-user guide. Every enabled feature has a
  documented section; the feature index maps every required feature id to
  its section and labels research features honestly.
- `docs/wiremudder/developer/` — build, contribution, architecture, and
  WireCore guidance. Preserves upstream rules from the inherited
  `CONTRIBUTING.md`, `docs/README.md`, and `docs/platform-builds.md`.
- `docs/wiremudder/package-author/` — the manifest format, the 13
  permission names, the 3 update-policy kinds, and the no-silent-expansion
  rule, matching `schemas/wiremudder/packages/manifest.schema.json`.
- `docs/wiremudder/design/` and `docs/wiremudder/operations/` — per-domain
  design and runbook docs written by owning nodes.
- `examples/wiremudder/` — executable examples validated against the real
  schemas and oracles.

## Evidence Discipline

Every claim in the docs is backed by machine-readable evidence
(SPEC-000-R08). Docs reference real commands and their exact observed
output (for example the `wire-packages-oracle` JSON). No capability is
described as working unless a test proves it; optional providers remain
visibly disabled until certified (SPEC-000-R07).

## Feature Index

`docs/wiremudder/user/feature-index.md` is generated from
`.agent/features/FEATURES.tsv` and maps each of the 237 required features
to its documentation section. The unit test `feature-documentation.sh`
fails if any required feature id is missing from the index, so the index
cannot drift from the catalog.

## Source Index Feed

The Help Knowledge Index (SPEC-018-R04) is generated reproducibly from
accepted docs, UI schemas, command catalog, configuration schemas, ADRs,
and sanitized source references. The user docs in this node are one of the
accepted source kinds.

## Privacy and Diagnostics

Privacy docs state what stays local and what leaves only with explicit
configuration and consent (SPEC-000-R09, SPEC-026-R08). Troubleshooting
docs guide users to previewable, redacted, reproducible support bundles
(SPEC-026-R07).

## Commands and Observed Behavior (2026-08-28)

- `wire-packages-oracle decisions "" "network,secrets,command_send"` →
  all denied, expansion = all three (matches package-author guide).
- `wire-packages-oracle decisions "network" "network,secrets,command_send"`
  → network granted; secrets + command_send denied.
- `wire-packages-oracle hash <expected> <actual>` →
  `{"hash":"verified"}` / `{"hash":"mismatch"}`.

## Rollback

All artifacts are additive under the authorized boundaries
(`docs/wiremudder/user/`, `docs/wiremudder/developer/`,
`docs/wiremudder/package-author/`, `examples/wiremudder/`,
`tests/wiremudder/ep037/`). Reverting the milestone commit removes them
without touching inherited source.
