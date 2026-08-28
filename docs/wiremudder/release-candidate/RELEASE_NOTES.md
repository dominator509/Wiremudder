# WireMudder 0.9.0-rc1 Release Notes

Channel: canary (release candidate). Not a stable release; not signed.

## Provenance

- Upstream repository: https://github.com/Mudlet/Mudlet.git
- Upstream pinned commit: `77086c295f4adf59197e586e689d19bdde8e1008`
- WireMudder source commit: `cb31f98b0427c9b356bc1819fdd4e8c96e3bf9ad`
- Prepared by agent (ipman-hermes) during EP-038 release-candidate hardening;
  never signed by a maintainer (SPEC-020-R09).

## What this candidate contains

- The pinned Mudlet-derived client foundation (classic gameplay, Qt UI,
  Lua scripting, mapper, profiles, imports).
- WireCore services built across EP-000..EP-038: platform certification,
  chaos/forced-failure suites, upstream-sync regression, documentation,
  package-author tooling, and full release-candidate hardening.
- Verified on this build host only (Linux). Windows and macOS remain
  development-only and unadvertised until certified with green evidence
  (SPEC-027-R08).

## Verify this candidate

- SHA256SUMS: verify every listed artifact with `sha256sum -c SHA256SUMS`.
- SBOM: `sbom.json` lists components, licenses, and the document hash.
- License notices: `LICENSES.txt`; full inventory in
  `licenses/wiremudder/licenses.json`.
- Compatibility: `COMPATIBILITY.md` (EP-036 matrix, Linux certified).

## Known limitations

- The binary is not signed (candidate channel; signing is a manual
  maintainer step for stable).
- Optional providers (AI, voice, immersion) are disabled by default and
  uncertified; they are absent from release claims.
- Full details: `KNOWN_RISKS.md` in this artifact set and
  `docs/wiremudder/release-candidate/KNOWN_RISKS.md`.
