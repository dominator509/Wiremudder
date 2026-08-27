#!/usr/bin/env sh
# EP-005 M3 E2E: optional WireCore failure preserves manual text
# gameplay. A P0 gameplay loop (100 ms tick) must never stall while:
#   1. WireCore is absent (disabled state, requests refused)
#   2. WireCore is up (optional work flows)
#   3. WireCore is SIGKILLed mid-session (supervisor restarts it)
# All against the real bridge implementation and real sidecar binary.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
SOCK=/tmp/wm-ep005-m3-e2e-$$.sock
HARNESS=/tmp/wm-ep005-m3-e2e-harness-$$
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

"$HARNESS" e2e "$SOCK" "$BIN" 2>&1 \
  || { echo "FAIL: e2e harness" >&2; exit 1; }
echo "e2e optional-failure-preserves-gameplay: ok"
