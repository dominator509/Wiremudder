# Secure Updater, Package Registry, and Rollback — Operations Runbook

## Overview

The WireMudder secure updater verifies signed manifests and artifacts before
any install. It never signs; signing keys are hardware-backed or
maintainer-controlled and absent from agent environments (SPEC-020-R09).
All update work is P4 and cannot block manual text gameplay (SPEC-004).

## Health and Readiness

- **Health**: the updater is healthy after a clean startup and required
  smoke checks. `StartupTracker` counts failed startups; after the bound
  (default 3) the subsystem is quarantined and rollback guidance is shown
  (WM-SPEC-020-R06).
- **Readiness**: verify with the node verifier:

  ```sh
  sh scripts/node-verifiers/EP-034.sh verify
  ```

- **Disable**: Local Only Lockdown (SPEC-010-R04) blocks all remote update
  and asset checks. The user may individually and visibly override a single
  check; there is no silent bypass.

## Upgrade

1. The client fetches the manifest for its channel/lane.
2. The manifest signature is verified (`verify_strict`) and the artifact
   SHA-256 and size are checked.
3. Admission applies: permission expansion, unexpected downgrade, staged
   rollout (fraction + kill switch), active-session deferral, lockdown.
4. Downloads resume from the exact interrupted offset (contiguous chunks).
5. A manifest with a higher migration version requires a completed backup
   before install and a restore on rollback (`plan_migration`).
6. After install the client restarts; clean startup and smoke checks confirm
   health. Failure increments the crash counter; a crash loop quarantines
   the update and offers rollback guidance.

## Rollback

- A quarantined update is replaced by restoring the previous healthy version
  from backup (WM-SPEC-028-R04).
- Any inherited-source edit in this node is reverted with:

  ```sh
  git checkout -- src/CMakeLists.txt
  ```

- Never cross a completed green tag during rollback (LOOPS.md).

## Backup and Restore

- Before a migration-bearing install, the previous version and its data are
  backed up locally. Restore uses that backup and re-applies the prior
  migration version.
- Backup/restore drill: run the LF-034 live-fire script:

  ```sh
  sh tests/live-fire/LF-034-signed-update-rollback.sh
  ```

## Recovery

- **Failed startup (single)**: reported as `failed_startup`; the next clean
  startup resets the counter.
- **Crash loop**: after the quarantine bound the update is quarantined;
  follow the on-screen rollback guidance and restore the previous healthy
  version.
- **Corrupted download**: the artifact hash mismatch is denied before
  install; re-download resumes from the last contiguous offset.
- **Denied update**: signature/hash/permission/downgrade/rollout denials are
  typed (SPEC-025) and never silently retried past the bounded retry class.

## Migration

A manifest with a higher `migration_version` requires a completed backup
before install and a restore on rollback (`plan_migration`). Migration is
planned per lane: `backup_required` (target > current), `none` (equal), or
`restore_required` (target < current). A migration never runs during an
active session and never silently bundles optional lanes (SPEC-020-R07/R08).

## Uninstall

The updater subsystem is optional (SPEC-020-R08): it can be disabled via
Local Only Lockdown, and its lanes (provider, context, command, plugin,
renderer, audio, model, help) are never silently bundled or enabled.

## Maintenance Changes

Maintenance uses the same Graphlock contracts, expected-file fences, tests,
evidence, and rollback as initial development (WM-SPEC-028-R08). Any change
to the updater must pass `sh scripts/node-verify.sh EP-034` and the live-fire
proof before a green tag.

## Commands Reference

```sh
# Generate an ephemeral TEST keypair (never for production)
cargo run --release --manifest-path tools/update-fixtures/Cargo.toml -- \
  gen-key /tmp/update-keys

# Sign a real artifact into a manifest (TEST ONLY)
cargo run --release --manifest-path tools/update-fixtures/Cargo.toml -- \
  sign /tmp/update-keys/keypair.json core.bin core_app stable 2.0.0

# Verify a signed manifest with the Rust core
cargo run --release --manifest-path wirecore/crates/wire-updater/Cargo.toml \
  --bin wire-updater-oracle -- verify-manifest <pubkey-hex> core.manifest.json

# Verify an artifact against its manifest
cargo run --release --manifest-path wirecore/crates/wire-updater/Cargo.toml \
  --bin wire-updater-oracle -- verify-artifact core.manifest.json core.bin

# Measure update hot-path performance
cargo run --release --manifest-path wirecore/crates/wire-updater/Cargo.toml \
  --example perf_fixture
```
