#!/usr/bin/env sh
# EP-007 M4 failure test: malformed and oversized input is rejected by
# both the C++ stores and the Rust core with typed errors, never by
# silent acceptance or partial state.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep007-m4-mal-$$
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

# C++ layer: malformed JSON, version mismatch, corrupt routing.json,
# oversized ids, duplicate ids (harness failures subcommand).
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" failures 2>&1 \
  || { echo "FAIL: C++ malformed-input matrix" >&2; exit 1; }

# Rust core: malformed JSON and version mismatch rejections (unit tests
# + oracle). The crate tests already assert MalformedJson and
# SchemaVersionMismatch; re-run them as the real check.
(cd wirecore/crates/wire-profiles && /root/.cargo/bin/cargo test --offline malformed) >/dev/null 2>&1 \
  || { echo "FAIL: Rust malformed profile test" >&2; exit 1; }
(cd wirecore/crates/wire-routing && /root/.cargo/bin/cargo test --offline duplicate) >/dev/null 2>&1 \
  || { echo "FAIL: Rust duplicate test" >&2; exit 1; }

echo "failure malformed-input: ok"
