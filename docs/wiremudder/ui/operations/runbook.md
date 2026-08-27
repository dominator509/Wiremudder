# UI Layer Operations (EP-012 M4)

## Health

- Unit: `sh tests/wiremudder/ep012/unit/001-terminal-boundary.sh`,
  `002-workspace-boundary.sh`, `003-editor-boundary.sh`
- UI smoke: `sh tests/wiremudder/ui/001-ui-smoke.sh`
- Integration: `sh tests/wiremudder/ep012/integration/001-session-flow.sh`
- E2E: `sh tests/wiremudder/ep012/e2e/001-user-visible-flow.sh`

## Readiness

The UI layer is ready when all unit, integration, and e2e suites pass and
the session flow persists/restores a layout file byte-identically across
process restarts.

## Disable

The UI boundaries are additive and optional. Removing
`src/wiremudder/ui/`, `src/wiremudder/models/`,
`tests/wiremudder/ui/`, and `docs/wiremudder/ui/` disables them. Raw
terminal text authority lives in the inherited TConsole path and never
depends on these boundaries (WM-SPEC-007-R03).

## Recovery

- Scrollback overflow: bounded ring; oldest lines dropped, newest always
  preserved; no recovery action needed.
- Corrupt layout JSON: `fromJson` returns false; the previous in-memory
  layout stays valid; delete the file and rebuild the layout.
- Capture filter misconfiguration: reset the filter; the source stream is
  never mutated.

## Backup and Restore

All UI artifacts are version-controlled. Layout files are per-profile
runtime state and can be regenerated. Restore source from git.

## Upgrade

Adding a UI feature requires: model struct, boundary method, unit test,
integration/e2e coverage, and design doc together (lockstep).

## Rollback

Revert the EP-012 M2/M3 commits. No inherited Mudlet file is modified;
rollback is clean.

## Measured Baseline (2026-08-27)

See `.agent/state/evidence/EP-012/M4/ui-latency.json`: terminal append
0.126 us, history add 0.109 us, spellcheck suggest 7.13 us (in-process,
O2). Budget: 10 ms. Worst-case headroom ~1400x.
