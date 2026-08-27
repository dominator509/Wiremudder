#!/usr/bin/env sh
# LF-005 sidecar-crash-isolation (live-fire)
#
# Proves the real user outcome of EP-005: the WireCore sidecar can be
# killed with SIGKILL mid-session while the real Qt supervisor is
# connected; the supervisor observes the crash, relaunches the sidecar
# with a fresh handshake, and the P0 manual gameplay loop never stalls
# (crash isolation). WireCore absent -> disabled state, requests
# refused, gameplay continues.
set -eu
fail() { echo "LF-005: FAIL - $1" >&2; exit 1; }

cd "$(dirname "$0")/../.."
QT=/opt/qt/6.8.2/gcc_64
[ -d "$QT" ] || fail "Qt 6.8.2 not at $QT"
SOCK=/tmp/wm-lf005-$$.sock
HARNESS=/tmp/wm-lf005-harness-$$
trap 'rm -f "$SOCK" "$HARNESS"' EXIT

echo "LF-005: sidecar-crash-isolation"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. Real sidecar binary.
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || fail "cargo build wirecore-runtime"
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || fail "sidecar binary missing"

# 2. Real C++ bridge implementation + harness.
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" tests/wiremudder/ep005/harness/wirecore_bridge_harness.cpp \
  src/wiremudder/bridge/wirecore_bridge.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" \
  -o "$HARNESS" || fail "harness compile"

# 3. The live outcome: absent -> disabled; up -> work flows; SIGKILL
#    mid-session -> supervisor restarts; P0 gameplay loop never stalls.
"$HARNESS" e2e "$SOCK" "$BIN" 2>&1 || fail "e2e supervision flow"

# 4. Socket permission is the local peer authentication boundary.
echo "LF-005: sidecar-crash-isolation ok"
