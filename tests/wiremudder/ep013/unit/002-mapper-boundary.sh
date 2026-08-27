#!/usr/bin/env sh
# EP-013 M2 unit test: C++ mapper boundary deterministic invariants.
# Compiles the real WorldGraphQt boundary with Qt 6.8.2 and runs the
# same invariant checks as the Rust crate (cross-implementation parity).
set -eu
cd "$(dirname "$0")/../../../.."

QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep013-m2-mapper-$$
trap 'rm -f "$HARNESS"' EXIT

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -d "$QT" ] || fail "Qt 6.8.2 not at $QT"
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core) \
  -I"$PWD" \
  tests/wiremudder/ep013/harness/mapper_harness.cpp \
  src/wiremudder/mapper/mapper_boundary.cpp \
  $(pkg-config --libs Qt6Core) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || fail "harness compile"

"$HARNESS" || fail "mapper boundary invariants"

echo "unit EP-013 M2 mapper-boundary: ok"
