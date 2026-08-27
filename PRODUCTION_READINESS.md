# WireMudder Production Readiness

A release profile is ready only when every applicable item has a verifying command or evidence path and all required nodes are DONE.

## Functional

- Feature matrix has no missing owner, specification, test, proof, source, or profile.
- Every enabled feature passes its requirement and live-fire route.
- Inherited classic behavior passes the compatibility oracle.
- Disabled optional capability is absent from release claims.

## Testing and Reality

- Blueprint, graph, feature, source, spec, adapter, and manifest gates pass.
- Format, lint, type, unit, integration, E2E, build, security, dependency, reality, smoke, and live-fire pass in one fresh run.
- No production mock, stub, demo success, sample success, or placeholder exists.
- Flaky tests are resolved.

## Security and Privacy

- Threat models and forced failures pass.
- No secrets are committed, logged, or exported.
- Local Only, consent, redaction, package permission, prompt injection, routing, command safety, signature, and rollback tests pass.
- SBOM, provenance, licenses, and notices are complete.

## Performance and Accessibility

- P0/P1 budgets and optional degradation pass on recorded hardware.
- Multi-session fairness and headless overhead pass.
- Keyboard, focus, semantics, non-color state, reduced motion, subtitles, and raw-text fallback pass.

## Data and Operations

- Migrations, backup, restore, export, deletion, corruption recovery, and index rebuild pass.
- Health, readiness, diagnostics, runbooks, incident, upgrade, and rollback drills pass.

## Distribution

- Clean supported-platform builds and installers pass.
- Checksums, signatures, SBOM, provenance, source, notices, compatibility matrix, and release notes are present.
- Exact manual signing and publish steps are prepared.
- Production remains unpublished by agents.

## Gate

Run `sh scripts/production-readiness-check.sh` and require `production readiness: ok` in the same session as the final `verify: ok`.
