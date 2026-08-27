#!/usr/bin/env sh
# EP-008 M3 integration test: global emergency stop.
# Engage cancels queued automation, blocks new proposals, releases cleanly
# (WM-SPEC-009-R06, WM-SPEC-017-R08); cancellation is audited.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep008-m3-estop-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" estop 2>&1 \
  || { echo "FAIL: estop harness" >&2; exit 1; }
echo "integration emergency-stop: ok"
