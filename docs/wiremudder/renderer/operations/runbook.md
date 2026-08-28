# WireMudder Retro Renderer — Operations Runbook (EP-025 M4)

## Health and readiness

- The renderer exposes a `RendererSnapshot` (mode, queue length, drops,
  coalesces, frozen, combat, pack/capsule/exit counts) through
  `RetroRenderer::snapshot()`. The UI boundary mirrors it
  (`RendererPaneQt`).
- Ready: mode `static` (default), queue length 0, drops 0.
- Degraded: worker crash — renderer falls back to `text-only`; raw text
  gameplay is never affected (WM-SPEC-016-R10).
- Disabled: mode `disabled`; emits denied; text gameplay fully
  independent.
- Denied: protected/unlicensed asset, invisible exit, or policy denial.

## Disable and emergency stop

- `set_mode(RendererMode::Disabled | TextOnly)` — queue cleared,
  renders nothing.
- `emergency_stop()` — cancels every queued emit and denies new work;
  manual text gameplay and connection controls are preserved
  (SPEC-009).
- Combat drops noncritical emits; critical combat/PvP emits still apply
  (SPEC-016-R07).

## Recovery

- After a worker crash: renderer is `text-only`; text continues.
  Re-enable by constructing a fresh renderer and calling `set_mode`
  with the desired mode.
- After an emergency stop: no automatic resume; the user must create a
  new ready renderer (SPEC-009 fail-closed).

## Backup and restore

- Renderer state is declarative: schemas under
  `schemas/wiremudder/renderer/` and the original asset manifest under
  `assets/wiremudder/renderer/`. Backup = copy these files; restore =
  replace and reload. No cloud account required (WM-SPEC-010-R10).
- User-owned packs follow the same manifest contract and can be
  exported/deleted/restored with their provenance.

## Upgrade and rollback

- Upgrade: build the new crate, keep schemas versioned (v1).
- Rollback: `git checkout -- src/CMakeLists.txt` reverts the single
  inherited edit; delete `src/wiremudder/ui/renderer/`,
  `wirecore/crates/wire-renderer/`, `schemas/wiremudder/renderer/`,
  `assets/wiremudder/renderer/` to remove the node's code. No migration
  or external provider state is touched (EP-025 fallback: static
  user-selected room backdrops; disable animation, inferred emits, and
  external asset generation).
