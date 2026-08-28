# EP-038 Release Candidate Operations Runbook

Operations instructions for the `0.9.0-rc1` canary release candidate.
Every procedure below uses real commands and the recorded artifact set in
`release/wiremudder/candidate/`.

## Health and readiness

A candidate is healthy when all of the following hold:

```sh
# Artifact set complete (10 files, signature omitted for candidate).
wirecore/target/release/wire-release-oracle dir-check release/wiremudder/candidate 0
# -> dir-ok 10

# Manifest is complete for the candidate channel.
wirecore/target/release/wire-release-oracle candidate-check release/wiremudder/candidate/manifest.json
# -> candidate-complete

# Every content artifact verifies.
(cd release/wiremudder/candidate && sha256sum -c SHA256SUMS)
# -> all OK
```

## Verification on a fresh host

```sh
sha256sum -c SHA256SUMS                        # artifact integrity
wirecore/target/release/wire-release-oracle candidate-check manifest.json
WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh
# -> release claims: ok features=244 profile=full
```

## Disable and quarantine

If a defect is found after freeze:

```sh
wirecore/target/release/wire-release-oracle revoke wm-0.9.0-rc1
# -> {"manifest_revoked":true,"rollout_paused":true,...}
```

Revocation is recorded in the rollout control; the manifest must NOT be
served to users after revocation. Do not delete the candidate dir — keep
it for forensics, but stop advertising it.

## Backup and restore

The candidate is reproducible from the recorded source commit:

```sh
# Source archive (byte-identical to the frozen artifact):
git archive --format=tar.gz <source_commit> > source.tar.gz

# Binary: rebuild the client from <source_commit> on this host; the
# rebuild must match the recorded sha256 in manifest.json. Any mismatch
# means the rebuild is not the frozen artifact and must not be shipped.
```

Restore a backup by copying the frozen candidate dir back into place and
re-running the health checks above.

## Upgrade and rollback

- Upgrade path: verify the new candidate (checksums + oracle + claims),
  then swap the candidate dir and re-run health checks.
- Rollback: restore the previous candidate dir (or rebuild from the
  previous source_commit) and re-run health checks. Never cross a
  completed green tag during rollback (AGENTS.md).
- The candidate is NOT signed and is NOT a stable release; do not present
  it as stable (SPEC-020-R09: agents never sign; stable requires a
  maintainer signature).

## Incident procedure

1. Record the symptom and the failing command's exact output.
2. Run `sha256sum -c SHA256SUMS` — a mismatch indicates corruption or
   tampering; quarantine the candidate and revoke.
3. If the oracle rejects the manifest, check `manifest.json` validity and
   that all artifact files are present with matching hashes.
4. If the claims gate fails, inspect
   `docs/wiremudder/release-candidate/CAPABILITY_MATRIX.tsv` for a stale
   state/evidence row and regenerate with
   `python3 tests/wiremudder/ep038/integration/gen-capability-matrix.py`.
5. Document the incident in the ledger and the node's Outcomes section.
