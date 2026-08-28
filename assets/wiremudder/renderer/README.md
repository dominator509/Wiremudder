# WireMudder Retro Renderer Assets (EP-025)

Original retro tile/sprite/diorama asset pack for WireMudder's optional
renderer. All assets in this directory are **original works generated
procedurally for this project** and dedicated to the public domain
(CC0-1.0). They are simple geometric retro-style tiles and sprites with
original palettes; they do **not** copy Nintendo, Zelda, Mario, or any
other third-party assets, sounds, trade dress, characters, or
proprietary style sheets (SPEC-016-R01).

The machine-readable manifest is `manifest.json` (schema:
`schemas/wiremudder/renderer/asset-pack-v1.json`). Every entry carries:

- `provenance` — `original:wiremudder:procedural`
- `license` — `CC0-1.0`
- `sha256` — content hash of the asset definition
- `user_local` — whether the user supplied it locally

User-owned packs follow the same manifest contract (WM-SPEC-016-R09):
license, provenance, hash, signature or user-local source, and
permissions. Protected or unlicensed packs are rejected by the
renderer's deterministic gate.
