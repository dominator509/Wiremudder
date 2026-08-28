# EP-039 Release Artifacts Design

## Artifact set (WM-SPEC-028-R05)

The release candidate (`release/wiremudder/candidate/`, EP-038) and the final
boundary (`release/wiremudder/final/`, EP-039) carry:

| Artifact | Path | Producer |
|---|---|---|
| Manifest | `manifest.json` | EP-038 candidate, EP-039 final |
| Provenance | `provenance.json` | EP-039 (agent-prepared, unsigned) |
| Checksums | `SHA256SUMS` | EP-038/EP-039 |
| SBOM | `sbom/wiremudder/SBOM.spdx.json` | EP-039 (SPDX 2.3) |
| License notices | `licenses/wiremudder/THIRD_PARTY_NOTICES.md` | EP-039 |
| Release notes | `RELEASE_NOTES.md` | EP-038/EP-039 |
| Compatibility | `COMPATIBILITY.md` | EP-036 evidence, copied |
| Known risks | `KNOWN_RISKS.md` | EP-038/EP-039 |
| Support | `SUPPORT.md` | EP-038, copied |
| Source archive | `source.tar.gz` | EP-038, reproducible |
| Binary | `wiremudder-bin` | EP-038 build |

## Evidence index

- `release/wiremudder/candidate/EVIDENCE_INDEX.json` — 14 entries covering the
  candidate artifact set.
- `.agent/state/final-evidence/index.json` — 425 entries over the entire
  `.agent/state/evidence/` corpus, each with a real sha256.
- `.agent/state/final-evidence/evidence-corpus.sha256` — aggregate hash.

## Honesty constraints

- `has_signature=false`, `prepared_by_agent=true`, `signed_by_maintainer=false`.
- `channel=canary`, `version=0.9.0-canary`, `auto_deploy=false`.
- The stable channel refuses the unsigned candidate (oracle `stable-check`).
- No claim in RELEASE_NOTES.md, KNOWN_RISKS.md, or the matrix exceeds
  evidence (SPEC-000-R08).

## Verification commands

- `sha256sum -c SHA256SUMS`
- `python3 scripts/production_readiness.py` → `production readiness structural: ok`
- `WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh`
  → `release claims: ok features=244 profile=full`
- `sh tests/wiremudder/ep039/unit/01-final-manifest-honest.sh` and the rest of
  the M2 unit suite.
