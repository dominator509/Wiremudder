#!/usr/bin/env sh
# EP-005 M3 integration test: crash isolation and supervised restart.
# Kills the real WireCore sidecar with SIGKILL while the real C++
# supervisor is connected; the supervisor must observe the crash,
# relaunch the sidecar, and complete a fresh handshake.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
SOCK=/tmp/wm-ep005-m3-crash-$$.sock
HARNESS=/tmp/wm-ep005-m3-crash-harness-$$
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

"$HARNESS" crash "$SOCK" "$BIN" 2>&1 \
  || { echo "FAIL: crash-restart harness" >&2; exit 1; }
echo "integration bridge-crash-restart: ok"
