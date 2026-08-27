#!/usr/bin/env sh
# EP-007 M4 security test: data integrity. Corrupt or tampered backing
# files fail load with a typed error; the store never enters a partial
# state; version mismatches are rejected.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep007-m4-int-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep007/harness/ep007_harness.cpp \
  src/wiremudder/profiles/character_profile_store.cpp \
  src/wiremudder/routing/route_profile_store.cpp \
  src/wiremudder/routing/router.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

# failures subcommand: corrupt routing.json rejected, version mismatch
# rejected, duplicate rejected, oversized id rejected.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" failures 2>&1 \
  || { echo "FAIL: integrity matrix" >&2; exit 1; }

# Rust core: malformed and version-mismatch rejections are unit-tested.
(cd wirecore/crates/wire-profiles && /root/.cargo/bin/cargo test --offline malformed_and_version) >/dev/null 2>&1 \
  || { echo "FAIL: Rust integrity tests" >&2; exit 1; }

echo "security data-integrity: ok"
