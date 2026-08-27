#!/usr/bin/env sh
# EP-005 M4 failure test: hang detection and recovery.
# Freezes the REAL WireCore sidecar with SIGSTOP (a hang, not a crash);
# the supervisor must detect stale pings (6 s threshold), restart the
# sidecar, and complete a fresh handshake.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
SOCK=/tmp/wm-ep005-m4-hang-$$.sock
HARNESS=/tmp/wm-ep005-m4-hang-harness-$$
trap 'rm -f "$SOCK" "$HARNESS"' EXIT

if [ ! -d "$QT" ]; then
  echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1
fi
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || { echo "FAIL: cargo build wirecore-runtime" >&2; exit 1; }
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || { echo "FAIL: sidecar binary missing" >&2; exit 1; }

export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" tests/wiremudder/ep005/harness/wirecore_bridge_harness.cpp \
  src/wiremudder/bridge/wirecore_bridge.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" \
  -o "$HARNESS" || { echo "FAIL: harness compile" >&2; exit 1; }

"$HARNESS" hang "$SOCK" "$BIN" 2>&1 \
  || { echo "FAIL: hang-detection harness" >&2; exit 1; }
echo "failure hang-detection: ok"
