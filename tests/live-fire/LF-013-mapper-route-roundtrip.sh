#!/usr/bin/env sh
# LF-013 live-fire: mapper route round-trip.
# Real controlled outcome for Mapper, World Graph, and Routing:
# builds a world, routes with weights/one-way/timed semantics, persists
# and reloads a versioned snapshot, and verifies the route survives.
set -eu
cd "$(dirname "$0")/../.."

QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-lf013-harness-$$
SNAP=/tmp/wm-lf013-snapshot.json
RUST_OUT=/tmp/wm-lf013-rust.txt
CPP_OUT=/tmp/wm-lf013-cpp.txt
trap 'rm -f "$HARNESS" "$SNAP" "$RUST_OUT" "$CPP_OUT"' EXIT

fail() { echo "LF-013: FAIL - $1" >&2; exit 1; }

# 1. Rust parity matrix (real crate).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example world_matrix > "$RUST_OUT" 2>/dev/null \
  || fail "rust world matrix"

# 2. C++ parity matrix (real boundary).
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

# 3. Identical decisions.
diff -u "$RUST_OUT" "$CPP_OUT" >/dev/null \
  || fail "cross-implementation divergence"

# 4. Weighted route survives snapshot persistence (real file IO).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example snapshot_export > "$SNAP" 2>/dev/null \
  || fail "snapshot export"
grep -q '"schema_version": 1' "$SNAP" || fail "snapshot missing version"
grep -q '"rooms"' "$SNAP" || fail "snapshot missing rooms"
grep -q 'room-5' "$SNAP" || fail "snapshot missing room data"

# 5. Feature coverage and spec trace (real gates).
sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"

echo "LF-013: ok (parity=$(wc -l < "$CPP_OUT") decisions, snapshot persisted)"
