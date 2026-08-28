# EP-038 Release Candidate Design

## Purpose

Freeze `0.9.0-rc1` (canary channel) as the Full release candidate, verify
every applicable gate, and make the candidate auditable, reproducible,
and reversible. This design records the exact commands, observed
behavior, and rollback for the release-candidate machinery built in
EP-038.

## Candidate layout

`release/wiremudder/candidate/` holds the frozen artifact set:

- `manifest.json` — schema v1 ReleaseManifest (channel canary, version
  `0.9.0-rc1`, upstream commit, source commit, artifact hashes, and the
  11 SPEC-028-R05 completeness flags).
- `source.tar.gz` — deterministic `git archive --format=tar.gz` of the
  recorded `source_commit` (reproducible byte-for-byte).
- `wiremudder-bin` — the real 247,337,512-byte Qt6 client binary built on
  this host from `build-linux-debug-nosan/src/mudlet`. Tracked by hash in
  the manifest; NOT committed to git (`.gitignore` amendment EP-038).
- `SHA256SUMS` — sha256 of every content artifact, verifiable with
  `sha256sum -c`.
- `sbom.json` — real SBOM generated from build inputs (EP-033).
- `provenance.json` — agent-prepared provenance: `prepared_by_agent:true`,
  `signed_by_maintainer:false`.
- `LICENSES.txt` — license notices generated from the real inventory
  `licenses/wiremudder/licenses.json` (7 components, EP-033).
- `RELEASE_NOTES.md`, `KNOWN_RISKS.md`, `COMPATIBILITY.md`, `SUPPORT.md` —
  release documentation; `KNOWN_RISKS.md` is mirrored at
  `docs/wiremudder/release-candidate/KNOWN_RISKS.md` as the canonical copy.

## Oracle decision (real output)

Built oracle: `wirecore/target/release/wire-release-oracle`.

- `candidate-check release/wiremudder/candidate/manifest.json`
  → `candidate-complete`
- `dir-check release/wiremudder/candidate 0` → `dir-ok 10`
- `stable-check release/wiremudder/candidate/manifest.json`
  → `stable-incomplete:stable release incomplete; missing: signature`
  (agents never sign; a maintainer signs for stable per SPEC-020-R09)

## Release claims

`docs/wiremudder/release-candidate/CAPABILITY_MATRIX.tsv` records one row
per feature (244 rows) with honest states derived from real evidence:

- 236 features live-fire-certified (owning node green + M5 evidence).
- 7 research features blocked (research-decision-required, not claimed).
- 1 feature tested (WM-FEAT-0244, EP-038's own feature; certified by
  LF-038 at M5).

Gate: `WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh`
→ `release claims: ok features=244 profile=full`.

## Verification commands

```sh
sha256sum -c release/wiremudder/candidate/SHA256SUMS
wirecore/target/release/wire-release-oracle candidate-check release/wiremudder/candidate/manifest.json
WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh
```

## Rollback

- Binary/archive: regenerate from source — `git archive --format=tar.gz
  <source_commit>` reproduces `source.tar.gz`; rebuild the client from the
  same commit for `wiremudder-bin`. Both hashes are recorded in
  `manifest.json` and `SHA256SUMS`; any mismatch fails verification.
- `.gitignore` amendment: `git checkout -- .gitignore` (recorded rollback
  in `.agent/expected-files/EP-038.discovered.txt`).
- Claims matrix: regenerate with `python3
  tests/wiremudder/ep038/integration/gen-capability-matrix.py`; the
  generator derives states from repository evidence only.
