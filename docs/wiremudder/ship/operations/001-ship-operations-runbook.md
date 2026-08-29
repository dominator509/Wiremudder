# EP-039 Ship and Operations Runbook

Applies to WireMudder 0.9.0-canary. Production is NOT deployed; these are the
exact manual steps a maintainer executes to publish (SPEC-028-R06).

## 1. Verify the release boundary

```
cd /root/wiremudder-repo
sha256sum -c release/wiremudder/final/SHA256SUMS          # both artifacts
python3 scripts/production_readiness.py                    # structural: ok
WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh  # 244 features
sh tests/wiremudder/ep039/unit/01-final-manifest-honest.sh
```

## 2. Install (maintainer, from the final boundary)

```
# The binary is 247 MB and reproducible from the source archive; install is
# manual by design (no auto-deploy):
install -m 0755 release/wiremudder/final/../candidate/wiremudder-bin /usr/local/bin/wiremudder
```

## 3. Manual signing (maintainer only — the agent never signs, SPEC-020-R09)

```
# Requires a maintainer PGP key. NEVER give the key to the agent.
gpg --detach-sign --armor release/wiremudder/final/wiremudder-bin
gpg --detach-sign --armor release/wiremudder/final/source.tar.gz
# Record the signature artifacts next to the binaries, then set
# has_signature=true in manifest.json ONLY after real signatures exist.
```

## 4. Publish (maintainer only)

```
# Stable publication also requires the updater manifest to carry the
# signature; the oracle refuses unsigned stable (stable-check).
# Upload to the release channel with the checksums + SBOM + provenance.
```

## 5. Rollback

```
# Restore the previous release directory:
git checkout <previous-release-tag> -- release/wiremudder/final/
# Downgrade policy: the updater rejects unexpected downgrades (SPEC-020-R04);
# a maintainer-approved downgrade must be signed and explicit.
```

## 6. Backup and restore

```
# The release boundary is fully reproducible from git:
git archive --format=tar.gz <source_commit> > /tmp/wiremudder-source.tar.gz
# Restore: checkout the source commit, rebuild, re-run the ship gate.
```

## 7. Upgrade and failed-update recovery

```
# In-place upgrade: replace the binary, verify sha256, restart.
# Failed update: keep the previous binary; the updater restores the previous
# healthy version (SPEC-020-R05) and crash loops trigger local quarantine
# (SPEC-020-R06).
```

## 8. Monitoring and revocation (SPEC-028-R07)

```
# Post-release monitoring is opt-in health signals + maintainer review.
# To pause rollout or revoke the manifest, use the oracle:
wirecore/target/release/wire-release-oracle revoke wm-0.9.0-canary
# (requires the maintainer-side key step; agent cannot perform it)
```

## 9. Known operational caveats

- The unit gate reports 106/110 ctest with four ADR-covered inherited
  failures (ADR-0016). Do not retry-until-green; read the ADR evidence.
- pcre2grep must be installed (pcre2-utils) or ReleaseTagVersionTest fails
  under CI=true.
- Xvfb on :99 and the luarocks Lua modules are required for the unit suite.
