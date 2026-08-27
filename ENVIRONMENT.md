# WireMudder Environment

## Baseline Source

The working repository must contain the Mudlet-derived source and be at or descend from `77086c295f4adf59197e586e689d19bdde8e1008` until EP-000 updates the lock through an accepted evidence change.

## Required Tools

- Git.
- POSIX shell environment; on Windows use the upstream-supported MSYS2 CLANG64 environment for native builds.
- Python 3 for Graphlock validators.
- CMake 3.25.1 or newer.
- A current Ninja and C++20 toolchain supported by the selected upstream preset.
- Qt6 development dependencies required by the inherited project.
- Rust and Cargo before EP-005.
- Clang-format, clang-tidy, cppcheck, and supply-chain tools as required by their nodes.

EP-000 records exact observed versions in `.agent/state/toolchain.lock.tsv`. This document does not invent versions that the target repository has not verified.

## Presets

Run `cmake --list-presets` and select a host-offered preset. Current upstream evidence describes `linux-debug`, `macos-debug`, `windows-debug`, no-sanitizer variants where supported, sanitizer variants, static-analysis variants, and `linux-lowspec`. EP-000 treats the actual target checkout as authority.

## Configuration

`.env` is local and ignored. Baseline values are in `.env.example`. Optional provider credentials are absent by default. Release signing secrets are never stored here.

## Environments

- Local development: local-only, development channel, no external telemetry, optional providers disabled until explicitly configured.
- CI: controlled fixtures and no user data; platform-specific clean builds.
- Release candidate: frozen dependencies and evidence index; no automatic publication.
- Stable: maintainer signed and manually published after EP-039.

## Troubleshooting Order

1. Run blueprint validation.
2. Run preflight.
3. Read upstream build skill.
4. Confirm selected preset and platform environment.
5. Inspect the active ExecPlan and ledger.
6. Run the narrowest failing wrapper.
7. Follow the bounded loop and never invent a replacement command.
