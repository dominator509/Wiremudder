#!/usr/bin/env sh
# EP-007 M4 failure test: resource and budget exhaustion. A store with
# hundreds of routes still validates and decides within bounds; oversized
# fields are rejected; a corrupt backing file fails load without partial
# state.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep007-m4-res-$$
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

# failures subcommand: 500-route store, oversized id rejection, corrupt
# routing.json load failure, closed-port timeout.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" failures 2>&1 \
  || { echo "FAIL: resource-exhaustion matrix" >&2; exit 1; }

# Rust core: bounded queue semantics are not part of this node, but the
# store must stay correct under bulk adds — the wire-routing test suite
# covers add/list/remove paths; run the full suite as the budget check.
(cd wirecore/crates/wire-routing && /root/.cargo/bin/cargo test --offline) >/dev/null 2>&1 \
  || { echo "FAIL: Rust routing suite" >&2; exit 1; }

echo "failure resource-exhaustion: ok"
