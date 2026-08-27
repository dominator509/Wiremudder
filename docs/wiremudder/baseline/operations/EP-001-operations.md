# WireMudder Baseline Operations — EP-001

## Health

- `sh scripts/validate-blueprint.sh` prints `blueprint validation: ok`.
- `sh scripts/preflight.sh` prints `preflight: ok`.
- The inherited client binary exists at `build-linux-debug-nosan/src/mudlet`
  and links Qt 6.8.2 from `/opt/qt/6.8.2/gcc_64`.

## Readiness

The baseline is ready when: configure cache exists
(`build-linux-debug-nosan/CMakeCache.txt`), the client binary is
executable, and `tests/wiremudder/ep001/` unit/integration/e2e tests pass.

## Configure and Build

```sh
cmake --preset linux-debug-nosan -DCMAKE_PREFIX_PATH=/opt/qt/6.8.2/gcc_64
cmake --build --preset linux-debug-nosan
ctest --preset linux-debug-nosan
```

Commands are locked in `.agent/state/COMMANDS.lock.tsv` (evidence
WM-SRC-000019). The Qt prefix requirement is recorded as WM-SRC-000032.

## Recovery and Restart

1. Confirm the toolchain: `cmake --version`, `ninja --version`,
   `pkg-config --modversion Qt6Core` (expect 6.8.2).
2. If Qt is missing, reinstall with aqtinstall:
   `aqt install-qt linux desktop 6.8.2 linux_gcc_64 -O /opt/qt -m qt5compat qtmultimedia`.
3. Reconfigure with the Qt prefix, rebuild, re-run the M3 verifier.

## Backup and Restore

- Build outputs are disposable: delete `build-linux-debug-nosan/` and
  rebuild. Source of truth is the git tree and `.agent/state/baseline/`.
- Evidence and ledger are in-git under `.agent/state/`.

## Upgrade and Rollback

- The baseline is the pinned upstream commit; upgrades happen only
  through an accepted upstream sync (SPEC-001-R06) on a dedicated branch.
- Rollback = `git revert` of the last milestone commit; never cross a
  completed `green/EP-XXX` tag.

## Incident Response

- Configure fails on Qt: verify `CMAKE_PREFIX_PATH` in
  `build-linux-debug-nosan/CMakeCache.txt` points at `/opt/qt/6.8.2/gcc_64`.
- Client aborts on startup with "platform plugins": install the xcb
  runtime libraries (libxcb-icccm4, libxcb-image0, libxcb-keysyms1,
  libxcb-render-util0, libxcb-xinerama0) and run under xvfb or offscreen.
- Build artifacts leaking into the source tree: `git status` shows them;
  delete and re-run `security/002-no-build-artifact-leak.sh`.
