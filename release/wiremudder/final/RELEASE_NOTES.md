# WireMudder 0.9.0-canary Release Notes

Channel: canary. Not a stable release; not signed; not auto-deployed
(SPEC-028-R06: AUTO_DEPLOY=false). Production publication requires a
maintainer signature and explicit publish action.

## Provenance

- Upstream repository: https://github.com/Mudlet/Mudlet.git
- Upstream pinned commit: `77086c295f4adf59197e586e689d19bdde8e1008`
- WireMudder source commit: `cb31f98b0427c9b356bc1819fdd4e8c96e3bf9ad`
- Prepared by agent (ipman-hermes) during EP-039 ship gate; never signed by a
  maintainer (SPEC-020-R09).

## Contents

- The pinned Mudlet-derived client foundation (classic gameplay, Qt UI, Lua
  scripting, mapper, profiles, imports).
- WireCore services built across EP-000..EP-038 plus the EP-039 ship gate
  (fresh verify, production-readiness, evidence index, release tag).
- Verified on this build host only (Linux). Windows and macOS remain
  development-only and unadvertised until certified (SPEC-027-R08).

## Known risks and unit-gate status

- 106/110 ctest pass. Four inherited functional-test isolation defects are
  recorded in `docs/wiremudder/ship/ADR-0016-*` with replacement evidence
  (ScriptEventHandlerLifetimeTest x2 order-dependent; ActionSelfRemovalTest
  deterministic boot-save race; TOscTest and ProfileRoundTripTest flaky races).
  All are byte-identical to the pinned upstream commit; upstream fixes
  (#9977/#9995/#10012/#10017/#10020) postdate the pin.
- Optional providers (AI, voice, immersion, external agents) are disabled by
  default and NOT certified (SPEC-000-R07/R08).
- The binary is unsigned; stable publication requires maintainer signature.

## Verify this release

- `sha256sum -c SHA256SUMS` over the two physical artifacts.
- SBOM: `sbom/wiremudder/SBOM.spdx.json` (hash `b38005dc13082e9c7a58b3fb1a0a08888235222eefb8e6803971f3403cf20f94`).
- License notices: `licenses/wiremudder/THIRD_PARTY_NOTICES.md`.
- Compatibility: `release/wiremudder/candidate/COMPATIBILITY.md` (Linux certified).
