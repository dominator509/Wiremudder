# WireMudder Accessibility Boundary — Operations Runbook

Node: EP-031 (Accessibility, Localization, and UX Hardening)

## Health

The accessibility boundary is a passive view-model. It has no service, no
port, no queue, and no worker. Health is a compile-and-model-invariant
property:

- The boundary compiles against the real Qt6 toolchain with zero warnings
  (`integration/accessibility-boundary-qt6.sh`).
- The unit harness asserts every model invariant
  (`tests/wiremudder/accessibility/unit_harness.cpp`).
- The e2e pane flow exercises all eight SPEC-025 states
  (`e2e/accessibility-pane-flow.sh`).

## Readiness

The boundary is ready when `AccessibilityPaneModel::state()` is `Ready`.
All other SPEC-025 states (Loading, Disabled, Denied, Degraded, Canceled,
Unavailable, Error) are explicit and non-blocking; raw terminal text is
always visible regardless of state (WM-SPEC-007-R03, WM-SPEC-016-R04).

## Disable

Disabling the accessibility surface does not disable text gameplay. To
disable the pane:

1. Remove `wiremudder/accessibility/accessibility_boundary.cpp` and
   `wiremudder/accessibility/accessibility_boundary.h` from
   `src/CMakeLists.txt` (the mudlet_SRCS list and the UI headers list).
2. Rebuild; the model-side boundary is not required by any other surface.

Alternatively, the pane reports `Disabled` state and stays passive; the
runtime behavior is identical to absence because the boundary has no
mutation path.

## Recovery

- If the boundary fails to compile: confirm `QTDIR=/opt/qt/6.8.2/gcc_64`
  and that `-Wall -Wextra` produce zero warnings. Re-run
  `tests/wiremudder/ep031/integration/accessibility-boundary-qt6.sh`.
- If the translation catalog fails lrelease: confirm the .ts is valid
  TS version 2.1 XML and every `<message>` has a `<source>` and a
  translator `<comment>`. Re-run
  `tests/wiremudder/ep031/integration/translation-build.sh`.
- If a harness fails with `version 'Qt_6.8' not found`: export
  `LD_LIBRARY_PATH=/opt/qt/6.8.2/gcc_64/lib` (the system libQt6Core is
  older than 6.8.2).

## Backup and Restore

The boundary is source-only; the repository is the backup. Restore any
node path with `git checkout -- <path>` or by reverting the milestone
commit. Do not cross a completed green tag during rollback.

## Upgrade

Translation catalogs follow the inherited Mudlet convention: edit the
master `translations/wiremudder/wiremudder.ts`, then run
`lrelease -compress -qm` (the exact flags used by
`translations/translated/CMakeLists.txt`). New strings MUST carry a
translator `<comment>` (WM-SPEC-007-R10).

## Rollback

- Boundary sources: remove `src/wiremudder/accessibility/`.
- CMake wiring: `git checkout -- src/CMakeLists.txt`.
- Translation catalog: remove `translations/wiremudder/`.
- Tests/docs: remove `tests/wiremudder/accessibility/`,
  `tests/wiremudder/ep031/`, and `docs/wiremudder/accessibility/`.

## Security

The boundary holds no secrets, no credentials, no keys, no network
access, and no process execution. It cannot render untrusted markup, send
commands, change settings, or disable raw text. No special handling is
required beyond the standard redaction rules for logs and evidence.
