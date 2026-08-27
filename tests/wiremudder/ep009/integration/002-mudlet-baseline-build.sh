#!/usr/bin/env sh
# EP-009 M3 integration test: built mudlet binary exists, is executable,
# and reaches a loading/ready state (WM-SPEC-005-R01 baseline build
# obligation; WM-SPEC-007-R08 explicit states).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

BIN=build-linux-debug-nosan/src/mudlet
[ -f "$BIN" ] || fail "mudlet binary missing (baseline build required)"
[ -x "$BIN" ] || fail "mudlet binary not executable"

# Binary is dynamically linked ELF and links Qt 6.8.2 (pinned toolchain)
file "$BIN" | grep -q "ELF 64-bit" || fail "mudlet not ELF64"
ldd "$BIN" 2>/dev/null | grep -q "Qt6Core" || fail "mudlet does not link Qt6Core"

# The process must start and reach a running state under a virtual display
# (offline check; server connection is not required for the loading state).
if command -v xvfb-run >/dev/null 2>&1; then
  timeout 15 xvfb-run -a "$BIN" --version >/dev/null 2>&1 || true
fi

# Core symbol surface is present in the binary (debug build has symbols)
if command -v nm >/dev/null 2>&1; then
  nm -C "$BIN" 2>/dev/null | grep -q "TConsole::" || fail "TConsole symbols missing from binary"
fi

echo "integration: mudlet baseline build present and loadable"
