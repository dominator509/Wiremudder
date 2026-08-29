# WireMudder 0.9.0-canary — Manual Signing & Publish Packet

Status: **agent-prepared, not signed, not published.** AUTO_DEPLOY=false at
every layer (WM-SPEC-028-R06). A maintainer with the release signing key
performs every step below on a trusted host. This packet contains **no key
material**; keys live only in the maintainer's secure environment.

## 1. Verify the boundary before signing

```sh
cd /path/to/wiremudder-repo
git rev-parse --verify refs/tags/green/EP-039        # all 39 nodes green
git rev-parse --verify refs/tags/release/wiremudder-0.9.0-canary
sha256sum -c release/wiremudder/candidate/SHA256SUMS  # inside candidate/
wirecore/target/release/wire-release-oracle candidate-check release/wiremudder/candidate/manifest.json
# expect: candidate-complete
```

## 2. Sign the artifacts (maintainer key; never automated)

```sh
cd release/wiremudder/candidate
# Sign the two payload artifacts with the release key. Output files:
gpg --detach-sign --armor --output source.tar.gz.sig source.tar.gz
gpg --detach-sign --armor --output wiremudder-bin.sig wiremudder-bin
# Record signature presence back into the manifest (maintainer edit: set
# has_signature=true and add the .sig artifact rows), then regenerate
# SHA256SUMS over the signed boundary:
sha256sum -c SHA256SUMS
```

## 3. Re-check stable readiness with the real oracle

```sh
wirecore/target/release/wire-release-oracle stable-check release/wiremudder/final/manifest.json
# expect: stable-complete (after signature recorded)
wirecore/target/release/wire-release-oracle dir-check release/wiremudder/final 1
# expect: dir-ok 11 (physical signature file present)
```

## 4. Publish (maintainer-only destination)

Upload the signed boundary to the release destination the maintainer
designates (artifact host / package index / update server). The agent never
performs or triggers this step. Record the published manifest id in the
release log:

```sh
wirecore/target/release/wire-release-oracle revoke <manifest-id>   # if recall needed
```

## 5. Post-publish health

Opt-in health signals and maintainer review may pause rollout or revoke the
update manifest (WM-SPEC-028-R07). The agent remains outside this loop.

## Rollback

Keep the previous signed candidate. Revert to it by re-pointing the update
channel to the prior manifest id and revoking the new one. Do not cross a
completed green tag.
