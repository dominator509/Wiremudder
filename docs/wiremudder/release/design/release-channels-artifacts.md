# Release Channels and Artifacts — Design

## Purpose

WireMudder ships through distinct release channels (development, canary,
beta, stable) with secure, provenance-aware artifacts (SPEC-020-R01,
SPEC-028-R05). This design covers the EP-035 release tooling: deterministic
artifact manifests, checksums, provenance, channel metadata, SBOM linkage,
post-install smoke, and manual publishing instructions. Stable publication
is always manual because AUTO_DEPLOY is false.

## Boundaries

- `packaging/wiremudder/` — `wire-release` Rust core. Computes artifact
  manifests, checksums, channel metadata, provenance, completeness checks,
  rollout revocation, and sync rehearsal. **Never signs and never
  publishes.** Signing keys stay outside agents (SPEC-020-R09).
- `CI/wiremudder/release-candidate.yml` — WireMudder release-candidate
  pipeline: builds the core, verifies channels, produces artifacts,
  computes SHA256SUMS, verifies completeness, uploads candidate artifacts.
- `installers/wiremudder/smoke.sh` — installer smoke: launch + user-data
  preservation on upgrade (acceptance obligation 2).
- `docs/wiremudder/release/` — design + operations runbook.
- `tests/live-fire/LF-035-installer-release-channel.sh` — live-fire proof.

## Flow

1. **Channel selection** — a maintainer chooses development/canary/beta/
   stable. Channels are distinct and correctly labeled; all publish
   manually (`requires_manual_publish`).
2. **Artifact production** — the pipeline produces source archive, binary,
   checksums, SBOM, provenance, license notices, release notes,
   compatibility matrix, known risks, and support instructions.
3. **Completeness** — `ReleaseManifest::complete_for_stable` requires every
   artifact including a signature; `complete_for_candidate` permits an
   agent-prepared candidate to omit only the signature (SPEC-020-R09).
4. **Verification** — `check_artifact_dir` hashes real files and fails
   closed on missing artifacts.
5. **Smoke** — the installer launches and preserves user data on upgrade;
   post-install checksums verify.
6. **Manual publish** — a human maintainer signs and publishes stable
   releases; the agent records recommendations and provenance only.
7. **Monitoring** — `RolloutControl` can pause a rollout or revoke an
   update manifest (SPEC-028-R07).

## Channels

| Channel | Purpose | Requires manual publish |
| --- | --- | --- |
| development | Daily builds | yes |
| canary | Automated nightly candidates | yes |
| beta | Feature validation | yes |
| stable | Signed, complete releases | yes (signing outside agents) |

## Security

- Agents prepare artifacts but never access signing keys or publish stable
  releases (SPEC-020-R09, acceptance obligation 6).
- Provenance records the upstream commit from `UPSTREAM.lock.yaml`
  (SPEC-001) and the source commit; build host is recorded.
- Release candidates never claim a signature: `is_agent_signed` is false
  for agent-prepared provenance.

## Performance

Release tooling is CI-side and P4; the deterministic core computes
checksums in O(bytes). Nothing in the release path blocks gameplay.

## Operations

Health, readiness, recovery, backup, restore, upgrade, rollback, disable,
and uninstall instructions live in
`docs/wiremudder/release/operations/runbook.md`.

## Commands

```sh
# Verify release channels
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- channels

# Check a stable release manifest for completeness
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- stable-check manifest.json

# Check a physical artifact directory (candidate: no signature required)
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- dir-check artifacts/ 0

# Compute a real SHA256
cargo run --release --manifest-path packaging/wiremudder/Cargo.toml \
  --bin wire-release-oracle -- sha256 artifact.bin

# Run the node verifier
sh scripts/node-verify.sh EP-035
```

## Rollback

- The release core is namespaced; no inherited workflow is edited.
- An unsafe release is paused/revoked via `RolloutControl`.
- A quarantined update is replaced by restoring the previous healthy
  version (SPEC-028-R04).
- Never cross a completed green tag during rollback (LOOPS.md).
