#!/usr/bin/env sh
# EP-008 M4 failure test: malformed input, unavailable command database,
# and queue exhaustion all fail closed with typed errors.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep008-m4-fail-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" failures 2>&1 \
  || { echo "FAIL: failure matrix" >&2; exit 1; }

# Rust core: empty/oversized rejection is unit-tested.
(cd wirecore/crates/wire-actions && /root/.cargo/bin/cargo test --offline empty_and_oversized) >/dev/null 2>&1 \
  || { echo "FAIL: Rust empty/oversized" >&2; exit 1; }

echo "failure malformed-input: ok"
