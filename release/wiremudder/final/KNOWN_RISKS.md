# WireMudder 0.9.0-canary Known Risks

## Unit gate

- 106/110 ctest passing. Two deterministic failures (ScriptEventHandlerLifetimeTest
  rename/delete order-dependency; ActionSelfRemovalTest profile-load save race) and
  two intermittent failures (TOscTest mpkg-notification race; ProfileRoundTripTest
  save-in-progress race) are inherited from the pinned upstream commit
  `77086c295f4adf59197e586e689d19bdde8e1008` and byte-identical to it.
  Replacement evidence and analysis: ADR-0016 (`docs/wiremudder/ship/`).
- Upstream has fixed this class after the pin (#9977, #9995, #10012, #10017, #10020);
  revisit on the next pin bump.

## Signing and publication

- The canary release is unsigned. Stable publication requires a maintainer
  signature; the agent never signs (SPEC-020-R09).
- AUTO_DEPLOY=false at all layers; no automatic publication.

## Platforms

- Linux certified on this build host (EP-036 evidence).
- Windows, macOS: development-only, NOT certified, NOT advertised.
