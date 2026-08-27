#!/usr/bin/env sh
# EP-005 M3 integration test: full WireCore bridge lifecycle.
# Real C++ supervisor (wirecore_bridge.cpp) + real Rust sidecar +
# real Unix socket. Exercises hello handshake, request/response,
# snapshot, cancellation, health ping/pong, and clean shutdown.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
SOCK=/tmp/wm-ep005-m3-life-$$.sock
HARNESS=/tmp/wm-ep005-m3-life-harness-$$
trap 'rm -f "$SOCK" "$HARNESS"' EXIT

# 1. Build the real sidecar (idempotent; lands where unit tests expect).
if [ ! -d "$QT" ]; then
  echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1
fi
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || { echo "FAIL: cargo build wirecore-runtime" >&2; exit 1; }
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || { echo "FAIL: sidecar binary missing" >&2; exit 1; }

# 2. Compile the harness against the real bridge implementation.
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" tests/wiremudder/ep005/harness/wirecore_bridge_harness.cpp \
  src/wiremudder/bridge/wirecore_bridge.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" \
  -o "$HARNESS" || { echo "FAIL: harness compile" >&2; exit 1; }

# 3. Run the real lifecycle against the real sidecar.
"$HARNESS" lifecycle "$SOCK" "$BIN" 2>&1 \
  || { echo "FAIL: lifecycle harness" >&2; exit 1; }
echo "integration bridge-lifecycle: ok"
