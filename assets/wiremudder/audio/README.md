# WireMudder Audio Assets (EP-026)

Original soundscape asset pack for WireMudder's optional soundscape
engine. All assets in this directory are **original works generated
procedurally for this project** and dedicated to the public domain
(CC0-1.0): short ambience loops, combat/boss/weather loops, and
death/victory cues with original palettes and patterns. They do **not**
copy Nintendo, Zelda, Mario, or any other third-party assets, sounds,
trade dress, characters, or proprietary style sheets (SPEC-016-R01).

The machine-readable manifest is `manifest.json` (schema:
`schemas/wiremudder/audio/asset-pack-v1.json`). Every entry carries:

- `provenance` — `original:wiremudder:procedural`
- `license` — `CC0-1.0`
- `sha256` — content hash of the asset definition
- `signature` — null for original procedural assets (user-local source
  is the trusted fallback for the local pack)
- `user_local` — whether the user supplied it locally

User-authored bindings and user-local loops follow the same manifest
contract (WM-SPEC-016-R09). Protected or unlicensed packs are rejected
by the soundscape engine's deterministic provenance gate, and remote
unsigned packs are rejected unless the user marks them local
(EP-026 fail-closed policy).

Playback remains optional: any audio failure degrades to silence and
text gameplay is always preserved (WM-SPEC-016-R10).
