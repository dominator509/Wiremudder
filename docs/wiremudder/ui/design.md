# WireMudder UI Design (EP-012 M2)

## Boundaries

- `src/wiremudder/ui/terminal_boundary.{h,cpp}` — TerminalPaneQt
  (WM-FEAT-0001/0003, WM-SPEC-007-R03 raw-text authority + bounded
  scrollback), CommandHistoryQt (WM-FEAT-0004, bounded + persisted),
  CapturePaneQt (WM-FEAT-0011, filtered copy, source untouched).
- `src/wiremudder/ui/workspace_boundary.{h,cpp}` — StatusGaugeQt
  (WM-FEAT-0012), ThemeQt (WM-FEAT-0021, WM-SPEC-027-R07 contrast
  state), WorkspaceLayoutQt (WM-SPEC-007-R04 named persistable layout).
- `src/wiremudder/ui/editor_boundary.{h,cpp}` — SpellcheckCore
  (WM-FEAT-0018, Levenshtein suggestions + autocorrect map),
  CompletionCore (WM-FEAT-0019, prefix completion).
- `src/wiremudder/models/workspace_models.h` — pure value structs.

## Invariants

1. Raw terminal text is stored unmodified and visible immediately; the
   ring bound drops oldest lines only, never the newest (WM-SPEC-007-R03).
2. Command history dedups consecutive entries and persists via JSON.
3. Capture panes copy filtered lines; the source stream is never mutated.
4. Workspace layouts round-trip through JSON with docks, gauges, theme.
5. Themes expose a high-contrast (non-color) readability state.
6. Spellcheck is deterministic: Levenshtein distance with sorted results.
7. Completion is case-insensitive prefix matching, sorted, bounded.

## Exact commands

```sh
sh tests/wiremudder/ep012/unit/001-terminal-boundary.sh
sh tests/wiremudder/ep012/unit/002-workspace-boundary.sh
sh tests/wiremudder/ep012/unit/003-editor-boundary.sh
sh tests/wiremudder/ui/001-ui-smoke.sh
```

## Rollback

Revert EP-012 M2 commit. No inherited Mudlet file is modified; all
surfaces are additive namespaced boundaries.
