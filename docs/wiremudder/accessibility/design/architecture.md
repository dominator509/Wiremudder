# WireMudder Accessibility, Localization, and UX Hardening — Design

Node: EP-031 (cross-cutting, high risk)
Dependencies: EP-012, EP-024, EP-025
Owning specs: SPEC-007, SPEC-015, SPEC-016, SPEC-018, SPEC-027
Owned requirement: WM-SPEC-007-R10

## 1. Purpose

Complete keyboard, focus, screen-reader, non-color state, reduced-motion,
large-text, subtitles, spoken feedback, raw-text fallback, translation, and
usability evidence across all enabled WireMudder surfaces. The node is a
cross-cutting release obligation: it does not own feature rows; it verifies
that the R05 obligations (owned by EP-009) hold across enabled surfaces and
owns the localization requirement R10.

## 2. Architecture

The node adds a passive Qt model boundary at
`src/wiremudder/accessibility/accessibility_boundary.h/.cpp` following the
established owned-pane pattern (help, soundscape, diagnostics, import).

- `AccessibilityPaneModel` exposes the accessibility profile:
  keyboard_operable, visible_focus, screen_reader_labels, non_color_state,
  large_text_resilient, reduced_motion, no_animation, subtitles_available,
  raw_text_mode, raw_text_authoritative.
- The model is a passive observer: it displays state and surfaces user
  intent only; it never sends commands, never changes settings, has no
  mutation path, cannot access secrets, and cannot egress.
- Raw terminal text is always visible and authoritative; the boundary
  cannot disable raw text (WM-SPEC-007-R03, WM-SPEC-016-R04).
- States follow SPEC-025: Loading, Ready, Disabled, Denied, Degraded,
  Canceled, Unavailable, Error.

The translation catalog at `translations/wiremudder/wiremudder.ts` mirrors
the inherited Mudlet convention exactly (WM-SPEC-007-R10):

- Master `.ts` with `TS version="2.1"` and a named context.
- Every new string carries a translator `<comment>` (context).
- Built with the real Qt6 `lrelease -compress -qm` (the same flags used by
  `translations/translated/CMakeLists.txt`).
- Runtime load path follows the inherited `QTranslator::load(userLocale,
  catalog, "_", ":/lang", ".qm")` convention (src/main.cpp:161).

## 3. Integration

The boundary translation unit is wired into the inherited
`src/CMakeLists.txt`:

- `wiremudder/accessibility/accessibility_boundary.cpp` in the
  `mudlet_SRCS` list beside `wiremudder/ui/help/help_boundary.cpp`.
- `wiremudder/accessibility/accessibility_boundary.h` in the UI headers
  list beside `wiremudder/ui/help/help_boundary.h`.

The discovered-path amendment (WM-SRC-000230) authorizes this inherited
edit.

## 4. Commands and Observed Behavior

All commands run from the repository root.

- Boundary compile against real Qt6 (zero warnings):

  ```
  g++ -std=c++17 -fPIC -c src/wiremudder/accessibility/accessibility_boundary.cpp \
    -I/opt/qt/6.8.2/gcc_64/include -I/opt/qt/6.8.2/gcc_64/include/QtCore -Wall -Wextra
  ```

- Unit harness (compiles + asserts model invariants):

  ```
  g++ -std=c++17 -fPIC -Isrc -I/opt/qt/6.8.2/gcc_64/include ... \
    tests/wiremudder/accessibility/unit_harness.cpp \
    src/wiremudder/accessibility/accessibility_boundary.cpp \
    -L/opt/qt/6.8.2/gcc_64/lib -Wl,-rpath,/opt/qt/6.8.2/gcc_64/lib -lQt6Core
  # run with LD_LIBRARY_PATH=/opt/qt/6.8.2/gcc_64/lib
  ```

- Translation build (inherited convention):

  ```
  /opt/qt/6.8.2/gcc_64/bin/lrelease translations/wiremudder/wiremudder.ts \
    -compress -qm <out>.qm
  ```

  Observed: `Updating '<out>.qm'... Generated 0 translation(s) (0 finished
  and 0 unfinished); Ignored 10 untranslated source text(s)` — the master
  catalog has 10 source strings awaiting locale translations, matching the
  inherited `type="unfinished"` master-catalog behavior.

## 5. Security and Privacy

The boundary has no secret access, no egress, no authority, no mutation
path. Untrusted MUD content cannot be rendered as trusted UI by this
boundary; it only reflects profile booleans and catalog metadata.

## 6. Performance

The model is a pure view-model (small fixed-size structs, no allocation in
state transitions beyond QString labels). No per-line blocking work; no
per-line cross-process or model calls (SPEC-007 performance obligation).

## 7. Rollback

- Boundary sources: remove `src/wiremudder/accessibility/` and
  `tests/wiremudder/accessibility/`.
- CMake wiring: `git checkout -- src/CMakeLists.txt`.
- Translation catalog: remove `translations/wiremudder/`.

The node never crosses a completed green tag during rollback.
