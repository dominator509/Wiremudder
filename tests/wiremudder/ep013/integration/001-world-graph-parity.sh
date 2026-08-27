#!/usr/bin/env sh
# EP-013 M3 integration test: cross-implementation parity oracle.
# The Rust wire-world-graph crate and the C++ WorldGraphQt boundary are
# both real implementations of the same world-graph rules; this test feeds
# the same scenarios to both and requires identical decisions
# (mirrors EP-006 egress policy oracle).
set -eu
cd "$(dirname "$0")/../../../.."

QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep013-m3-parity-$$
RUST_OUT=/tmp/wm-ep013-m3-rust.txt
CPP_OUT=/tmp/wm-ep013-m3-cpp.txt
trap 'rm -f "$HARNESS" "$RUST_OUT" "$CPP_OUT"' EXIT

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. Rust side.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example world_matrix > "$RUST_OUT" 2>/dev/null \
  || fail "rust world matrix"

# 2. C++ side.
[ -d "$QT" ] || fail "Qt 6.8.2 not at $QT"
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core) \
  -I"$PWD" \
  tests/wiremudder/ep013/harness/mapper_parity.cpp \
  src/wiremudder/mapper/mapper_boundary.cpp \
  $(pkg-config --libs Qt6Core) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || fail "parity harness compile"
"$HARNESS" > "$CPP_OUT" 2>&1 || fail "cpp world matrix"

# 3. Identical decisions, same order.
if ! diff -u "$RUST_OUT" "$CPP_OUT"; then
  fail "cross-implementation world-graph divergence"
fi
echo "integration world-graph-parity: ok ($(wc -l < "$CPP_OUT") decisions identical)"
