#!/usr/bin/env sh
# EP-008 M4 failure test: denied policy is deterministic. A deny rule
# wins over any model confidence; destructive actions require
# confirmation; automation-disabled and disconnected states block.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep008-m4-deny-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" gateway >/dev/null 2>&1 \
  || { echo "FAIL: gateway denial matrix" >&2; exit 1; }
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" failures >/dev/null 2>&1 \
  || { echo "FAIL: failures denial matrix" >&2; exit 1; }

# Rust core: no-high-confidence-shortcut + denied policy unit tests.
(cd wirecore/crates/wire-actions && /root/.cargo/bin/cargo test --offline no_high_confidence) >/dev/null 2>&1 \
  || { echo "FAIL: Rust no-shortcut" >&2; exit 1; }
(cd wirecore/crates/wire-policy && /root/.cargo/bin/cargo test --offline tier_confirmation) >/dev/null 2>&1 \
  || { echo "FAIL: Rust tier confirmation" >&2; exit 1; }

echo "failure denied-policy: ok"
