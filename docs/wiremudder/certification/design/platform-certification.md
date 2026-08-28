# Platform Certification — Design

## Purpose

WireMudder certifies clean Windows, macOS, and Linux flows; exercises
dependency, process, network, storage, provider, package, update, and
resource faults; and proves an upstream sync does not break contracts
(SPEC-027-R08). This design covers the EP-036 certification harness:
platform certification with real evidence, chaos fault injection, and
upstream sync regression.

## Boundaries

- `tests/wiremudder/platform/` — platform certification suites. The Linux
  host is certified with real evidence (clean builds, full unit suites,
  installer smoke). Windows/macOS certification requirements are documented
  in the compatibility matrix and are never claimed without evidence.
- `tests/wiremudder/chaos/` — chaos fault injection against the real
  updater and release cores: unavailable dependencies, corrupted inputs,
  killed workers, storage pressure, crash loops, and incomplete releases.
- `compatibility/platform/matrix.md` — honest per-platform status.
- `docs/wiremudder/certification/` — design + operations runbook.
- `tests/live-fire/LF-036-platform-chaos-matrix.sh` — live-fire proof.

## Certification Flow

1. **Clean build** — release core and updater core compile with zero
   warnings on the certified platform.
2. **Full suites** — unit suites pass on the platform.
3. **Packaging** — the release artifact set is produced and verified.
4. **Upgrade** — the installer launches and preserves user data on upgrade.
5. **Rollback** — crash loops quarantine and offer rollback guidance.
6. **Smoke** — post-install checksums verify.
7. **Evidence** — every step writes raw output under
   `.agent/state/evidence/EP-036/`.

A platform is certified only with complete green evidence (SPEC-027-R08);
otherwise it is development-only and unadvertised (EP-036 fallback).

## Chaos Flow

Faults are injected with real controlled mechanisms against real cores:

- Unavailable dependency → fail closed (nonzero exit / typed denial).
- Corrupted input → denied (verification).
- Killed worker → resume from last contiguous offset.
- Storage pressure → oversized input rejected (resource exhaustion).
- Crash loop → quarantine; clean startup recovers.
- Incomplete release → dir-check fails closed.

Every fault asserts typed errors, redacted logs, audit, cleanup,
compensation, quarantine, retry bounds, and preserved gameplay (SPEC-025).

## Upstream Sync Regression

The pinned upstream commit (`UPSTREAM.lock.yaml`) must remain an ancestor of
HEAD. Before every stable release, sync is rehearsed and generic fixes are
assessed for contribution (SPEC-028-R09). A sync that breaks a contract
blocks certification.

## Security

Certification and chaos never touch signing keys, never egress, and never
mutate inherited gameplay sources. Secrets never enter evidence; logs are
redacted (SPEC-010, SPEC-022).

## Performance

Chaos and certification work is CI/test-side and P4; nothing in the flow
blocks gameplay (SPEC-004).

## Operations

Health, readiness, recovery, backup, restore, upgrade, rollback, disable,
and uninstall instructions live in
`docs/wiremudder/certification/operations/runbook.md`.

## Commands

```sh
# Platform certification (Linux host)
sh tests/wiremudder/platform/linux-certification.sh

# Chaos fault injection
sh tests/wiremudder/chaos/fault-injection.sh

# Run the node verifier
sh scripts/node-verify.sh EP-036
```

## Rollback

- Certification claims are bounded by evidence; a platform without green
  evidence is not advertised.
- An unsafe release is paused/revoked via the release rollout control.
- Never cross a completed green tag during rollback (LOOPS.md).
