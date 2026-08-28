# Platform Certification, Chaos, and Upstream Sync Regression — Operations Runbook

## Overview

WireMudder certifies clean platform flows, exercises faults, and proves
upstream sync does not break contracts (SPEC-027-R08). A platform is
certified only with complete green evidence; otherwise it is
development-only and unadvertised (EP-036 fallback).

## Health and Readiness

- **Health**: the certification harness passes on the certified platform:

  ```sh
  sh tests/wiremudder/platform/linux-certification.sh
  ```

- **Readiness**: the node verifier passes:

  ```sh
  sh scripts/node-verifiers/EP-036.sh verify
  ```

- **Disable**: certification/chaos are CI-side; no runtime component exists
  to disable.

## Certification

1. Clean build (zero warnings) of the release core and updater core.
2. Full unit suites pass on the platform.
3. Packaging produces source, binary, checksums, SBOM, provenance.
4. Installer launches and preserves user data on upgrade.
5. Rollback: crash loops quarantine and offer rollback guidance.
6. Post-install smoke passes.
7. Evidence is retained under `.agent/state/evidence/EP-036/`.

Linux is certified on this host. Windows/macOS remain development-only until
matching evidence exists (see `compatibility/platform/matrix.md`).

## Chaos Drills

- Unavailable dependency: fails closed.
- Corrupted input: denied (verification).
- Killed worker: download resumes from the last contiguous offset.
- Storage pressure: oversized input rejected (resource exhaustion).
- Crash loop: quarantine; clean startup recovers.
- Incomplete release: dir-check fails closed.

Run the drill:

```sh
sh tests/wiremudder/chaos/fault-injection.sh
```

## Recovery

- A quarantined update is replaced by restoring the previous healthy version.
- Release candidates are reproducible; re-running the pipeline reproduces
  the artifact set.
- An unsafe release is paused/revoked via the release rollout control.

## Upstream Sync Regression

The pinned upstream commit (`UPSTREAM.lock.yaml`) must remain an ancestor of
HEAD. Before every stable release, sync is rehearsed and generic fixes are
assessed for contribution (SPEC-028-R09). A sync that breaks a contract
blocks certification.

## Security

Certification and chaos never egress, never touch signing keys, and never
mutate inherited gameplay sources. Evidence is redacted (SPEC-010,
SPEC-022).

## Maintenance Changes

Maintenance uses the same Graphlock contracts, expected-file fences, tests,
evidence, and rollback as initial development (WM-SPEC-028-R08). Any change
must pass `sh scripts/node-verify.sh EP-036` and the live-fire proof before
a green tag.

## Commands Reference

```sh
sh tests/wiremudder/platform/linux-certification.sh
sh tests/wiremudder/chaos/fault-injection.sh
sh tests/live-fire/LF-036-platform-chaos-matrix.sh
sh scripts/node-verify.sh EP-036
```
