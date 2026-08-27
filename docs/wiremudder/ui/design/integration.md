# WireMudder UI Integration (EP-012 M3)

## Integration flow

The session flow (`harness session <layout.json>`) drives all UI
boundaries from one controlled text stream (SIMULATION: in-process
stream, not a live server):

1. Raw stream lines land in `TerminalPaneQt` unmodified and immediately
   visible (WM-SPEC-007-R03).
2. `CapturePaneQt` mirrors matching lines only; the source is never
   mutated (WM-FEAT-0011).
3. Commands flow into `CommandHistoryQt`; `CompletionCore` assists
   (WM-FEAT-0004/0019).
4. `StatusGaugeQt` reflects state changes (WM-FEAT-0012).
5. `WorkspaceLayoutQt` persists to a real JSON file and restores on a
   second process run (WM-SPEC-007-R04 restart behavior).

## Exact commands

```sh
sh tests/wiremudder/ep012/integration/001-session-flow.sh
sh tests/wiremudder/ep012/e2e/001-user-visible-flow.sh
```

## Observed behavior

- Session flow: ok; layout persisted: ok (name=combat, dock=capture,
  gauge hp=63, theme night high-contrast).
- E2E: first session writes layout; second process restores identical
  bytes (cmp ok); corrupt layout never affects raw-text authority.

## Degraded states

- Capture filter with no matches: capture pane empty, terminal pane
  keeps all raw lines (WM-SPEC-007-R03 preserved).
- Corrupt/partial layout JSON: restore fails cleanly; manual text
  gameplay unaffected.

## Rollback

Revert the EP-012 M3 commit. Boundaries are additive; no inherited file
is modified.
