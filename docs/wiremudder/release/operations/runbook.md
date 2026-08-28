# Release Channels and Artifacts — Operations Runbook

## Overview

WireMudder ships release candidates through development, canary, beta, and
stable channels (SPEC-020-R01). The release core (`wire-release`) prepares
artifacts deterministically; agents never sign and never publish stable
releases (SPEC-020-R09). Stable publication is manual because AUTO_DEPLOY is
false (SPEC-028-R06).

## Health and Readiness

- **Health**: the release core builds and its unit suite passes:

  ```sh
  cargo test --manifest-path packaging/wiremudder/Cargo.toml
  ```

- **Readiness**: the release channel pipeline is ready when the node
  verifier passes:

  ```sh
  sh scripts/node-verifiers/EP-035.sh verify
  ```

- **Disable**: the release pipeline is CI-side and never runs during
  gameplay; no runtime component exists to disable.

## Release Candidate Production

1. A maintainer selects a channel (development/canary/beta/stable).
2. The pipeline produces: source archive, binary, checksums, SBOM,
   provenance, license notices, release notes, compatibility matrix, known
   risks, support instructions (SPEC-028-R05).
3. `dir-check` verifies the physical artifact directory:
   - Candidate (no signature): `dir-check <dir> 0`
   - Stable (signature required): `dir-check <dir> 1`
4. Checksums are computed with the release core:

   ```sh
   cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
     --bin wire-release-oracle -- sha256 <file>
   ```

## Upgrade, Rollback, and Recovery

- **Upgrade**: installers preserve user data on upgrade (proven by
  `installers/wiremudder/smoke.sh`).
- **Rollback**: an unsafe release is paused or its update manifest revoked
  via `RolloutControl` (SPEC-028-R07). A quarantined update is replaced by
  restoring the previous healthy version.
- **Recovery**: release candidates are reproducible; re-running the pipeline
  reproduces the artifact set. Provenance records the upstream commit and
  source commit for audit.
- **Backup and restore**: artifact sets are content-addressed by SHA256;
  restore by re-fetching the recorded checksums.

## Upstream Sync Rehearsal

Before every stable release, upstream sync is rehearsed (SPEC-028-R09):

```sh
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- sync-ready manifest.json
```

A `sync-pending` result blocks stable readiness until rehearsal and generic
fix assessment are recorded.

## Manual Publish (Stable)

1. Verify the complete artifact set: `stable-check manifest.json`.
2. A human maintainer signs the artifacts (signing keys never enter agent
   environments).
3. The maintainer publishes the release; the agent never publishes.
4. Post-release monitoring uses opt-in health signals; a maintainer can
   pause rollout or revoke an update manifest (SPEC-028-R07).
5. RUN_COMPLETE is appended only after the release tag and all observed gate
   sentinels are recorded (SPEC-028-R10).

## Uninstall / Disable

The release pipeline has no runtime surface. Remove the CI workflow or the
release core to disable; stable releases already shipped remain unaffected.

## Maintenance Changes

Maintenance uses the same Graphlock contracts, expected-file fences, tests,
evidence, and rollback as initial development (WM-SPEC-028-R08). Any change
must pass `sh scripts/node-verify.sh EP-035` and the live-fire proof before
a green tag.

## Commands Reference

```sh
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- channels
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- stable-check manifest.json
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- candidate-check manifest.json
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- dir-check <dir> <require-sig:0|1>
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- provenance
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- revoke <manifest-id>
```
