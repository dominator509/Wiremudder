# WireMudder 0.9.0-rc1 Known Risks

Honest list of known risks and disabled capabilities for this release
candidate. A risk is recorded when real evidence shows it exists; nothing
here is invented, and anything not proven certified is explicitly not
claimed.

## Certified vs not certified

- Linux: certified on this build host (EP-036 evidence).
- Windows, macOS: development-only, NOT certified, NOT advertised.
- Optional providers (AI, voice, immersion, external agents): disabled by
  default, NOT certified, NOT claimed. Enabling them requires per-provider
  live-fire certification (SPEC-000, SPEC-027).

## Supply chain and signing

- The candidate binary is NOT signed. `has_signature=false` is recorded in
  the manifest. Stable publication requires a maintainer signature
  (SPEC-020-R09); the agent never signs.
- The 247 MB binary is tracked by hash in the manifest and SHA256SUMS but
  is not committed to git; it is reproducible from the source archive at
  the recorded `source_commit`.
- SBOM (`sbom.json`) and license inventory (`licenses/wiremudder/
  licenses.json`) are generated from real build inputs (EP-033).

## Build and tooling

- `clang-format` is absent on this host; 1073 pre-existing formatting
  violations exist in inherited code. No formatting gate is run.
- The EP-018 blueprint ellipsis preflight check FAILs (documented; the
  ellipsis is outside this node's fence). This is a pre-existing
  documentation gap, not a runtime defect.

## Release operations

- `WIREMUDDER_AUTO_DEPLOY=false` at three real layers (.env,
  `scripts/probes/auto_deploy.sh`, `scripts/production-readiness-check.sh`);
  EP-039 will not auto-publish.
- Rollback: restore the previous release directory and re-run
  `SHA256SUMS -c`; see `docs/wiremudder/release-candidate/operations/`.
