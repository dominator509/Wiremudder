# WireMudder Inherited Baseline — design notes (EP-001 M2)

## Baseline Definition

The inherited baseline is the pinned Mudlet development commit
`77086c295f4adf59197e586e689d19bdde8e1008` with the Graphlock overlay
installed and no functional WireMudder changes. EP-001 proves this
baseline configures, builds, and tests with the discovered commands.

## Boundaries

- New WireMudder code lives under `src/wiremudder/`, `wirecore/`,
  `schemas/wiremudder/`, `tests/wiremudder/`, `docs/wiremudder/`.
- Inherited source is edited only through an evidence-backed discovered
  path amendment (SPEC-002-R02).
- Qt remains the single desktop shell (SPEC-002-R08).

## Toolchain (recorded 2026-08-27)

- cmake 3.28.3 (>= 3.25.1 required by inherited CMakeLists)
- ninja 1.11.1, g++ 13.3.0 (C++20)
- Lua 5.1.5 + pkg-config (lua5.1)
- Qt 6.4.2 (Qt6Core/Declarative/Multimedia/Tools/WebSockets/Svg dev)
- python 3.12.3, rust 1.96.0 (rust required from EP-005 onward)

## Build Pattern

`cmake --preset linux-debug-nosan` (locked in COMMANDS.lock.tsv, evidence
WM-SRC-000019), builds into `build-linux-debug-nosan/`, binary at
`build-linux-debug-nosan/src/mudlet`.
