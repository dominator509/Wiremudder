#!/usr/bin/env sh
# WM-FEAT-0165: zones and area clustering.
# Runs the real world-graph zone invariants (Rust crate unit test + C++).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0165: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml zones_cluster \
  > /tmp/wm-feat-0165.log 2>&1 \
  || { tail -10 /tmp/wm-feat-0165.log >&2; fail "zones unit test"; }
grep -q "test result: ok" /tmp/wm-feat-0165.log || fail "zones test not ok"

QT=/opt/qt/6.8.2/gcc_64
[ -d "$QT" ] || fail "Qt 6.8.2 missing"
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
HARNESS=/tmp/wm-feat-0165-harness-$$
trap 'rm -f "$HARNESS"' EXIT
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core) -I"$PWD" \
  tests/wiremudder/ep013/harness/mapper_harness.cpp \
  src/wiremudder/mapper/mapper_boundary.cpp \
  $(pkg-config --libs Qt6Core) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || fail "harness compile"
"$HARNESS" || fail "C++ zone invariants"

echo "feature-0165 zones-and-area-clustering: ok"
