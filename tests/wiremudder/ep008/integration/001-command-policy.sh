#!/usr/bin/env sh
# EP-008 M3 integration test: command policy invariants.
# Deterministic risk tiers, deny/allow rules, argument validation,
# Human-Tempo pacing (WM-FEAT-0174..0177).
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep008-m3-policy-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" policy 2>&1 \
  || { echo "FAIL: policy harness" >&2; exit 1; }
echo "integration command-policy: ok"
