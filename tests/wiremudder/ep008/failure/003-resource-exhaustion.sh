#!/usr/bin/env sh
# EP-008 M4 failure test: resource exhaustion. The visible queue is
# bounded; a full queue denies new entries; emergency stop cancels all
# queued automation and blocks new proposals.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep008-m4-res-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" estop >/dev/null 2>&1 \
  || { echo "FAIL: estop matrix" >&2; exit 1; }

# Rust core: bounded queue + estop cancellation unit tests.
(cd wirecore/crates/wire-actions && /root/.cargo/bin/cargo test --offline queue_is_bounded) >/dev/null 2>&1 \
  || { echo "FAIL: Rust queue bound" >&2; exit 1; }
(cd wirecore/crates/wire-actions && /root/.cargo/bin/cargo test --offline emergency_stop_cancels) >/dev/null 2>&1 \
  || { echo "FAIL: Rust estop" >&2; exit 1; }

echo "failure resource-exhaustion: ok"
