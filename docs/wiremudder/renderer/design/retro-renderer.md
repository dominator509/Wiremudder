# Retro Renderer, Diorama, and Visual Emits — Design (EP-025 M3)

## Purpose

Original retro room backdrops, diorama/tile/sprite surfaces, visual
emit extraction, overlays, clickable exits, provenance, confidence,
caching, frame budgets, and static/text fallback (SPEC-016, SPEC-004,
SPEC-012, SPEC-022).

## Architecture

- `wirecore/crates/wire-renderer/` — namespaced new code:
  `RetroRenderer` (mode state machine, bounded frame-budgeted emit
  queue with drop/coalesce, combat suppression, emergency stop,
  provenance tracking, degrade-to-text), `EmitKind` (complete catalog),
  `VisualEmit` (confidence), `RendererEmitCandidate` (typed event),
  `ClickableExit` -> `ExitProposal` (SPEC-009), `AssetManifestEntry`
  (license/provenance/hash/signature/permissions), `StyleCapsule`.
- `src/wiremudder/ui/renderer/renderer_boundary.{h,cpp}` — model-side
  Qt surface following the pane pattern. Passive: no command path, no
  gate editing, raw text authority preserved. Compiled into the actual
  client via `src/CMakeLists.txt` (discovered amendment WM-SRC-000168).
- `schemas/wiremudder/renderer/` — snapshot, emit, asset-pack,
  style-capsule JSON schemas (versioned, v1).
- `assets/wiremudder/renderer/` — original procedural tile/sprite
  assets (CC0), provenance `original:wiremudder:procedural`.

## Key invariants

1. Assets are original or properly licensed; protected assets are
   rejected by the deterministic gate (SPEC-016-R01/R09).
2. Raw text remains visible and authoritative; clickable exits propose
   only and can never spoof trusted commands (SPEC-016-R04).
3. Visual emits cover the complete catalog with visible confidence when
   inferred (SPEC-016-R03).
4. Frame-budgeted queue (128 cap, 5 ms target) drops/coalesces
   noncritical emits and freezes to static before terminal performance
   degrades (SPEC-016-R06).
5. No live art generation in combat or the hot path (SPEC-016-R07).
6. Renderer worker failure disables immersion and preserves text
   gameplay (SPEC-016-R10).

## Exact commands and observed behavior

- `cargo test --manifest-path wirecore/crates/wire-renderer/Cargo.toml`
  -> `test result: ok. 16 passed`
- `cargo run --example e2e_renderer` -> `E2E renderer: ok` with asset
  provenance, complete catalog, frame budget, clickable exits, modes,
  and crash-to-text lines.
- Boundary compile vs real Qt6 (`/opt/qt/6.8.2/gcc_64`):
  `c++ -std=c++20 -fPIC -I/root/wiremudder-repo -I$QT/include
  -I$QT/include/QtCore -c src/wiremudder/ui/renderer/renderer_boundary.cpp`
  -> object produced; boundary asserts `canSendCommand()==false`,
  `canEditGates()==false`, `isPassive()==true`.

## Rollback

- `git checkout -- src/CMakeLists.txt` reverts the single inherited
  edit; deleting `src/wiremudder/ui/renderer/` removes the boundary.
- Removing `wirecore/crates/wire-renderer/`,
  `schemas/wiremudder/renderer/`, `assets/wiremudder/renderer/` reverts
  the new code (all namespaced).
- No migration or external provider state is touched; renderer is
  optional. Fallback: static user-selected room backdrops; disable
  animation, inferred emits, and external asset generation.
