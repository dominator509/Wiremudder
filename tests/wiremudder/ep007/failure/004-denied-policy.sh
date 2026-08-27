#!/usr/bin/env sh
# EP-007 M4 failure test: denied permission, consent, route, and policy.
# Automation cannot change routing/AI defaults or create profiles
# (WM-SPEC-006-R08); disabled future route kinds are rejected; missing
# selection blocks; direct is only used when explicitly selected.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep007-m4-deny-$$
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

# C++ layer: profiles subcommand asserts automation denied for routing,
# future kinds disabled, missing selection blocked.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" profiles >/dev/null 2>&1 \
  || { echo "FAIL: profiles denial matrix" >&2; exit 1; }
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" routing >/dev/null 2>&1 \
  || { echo "FAIL: routing denial matrix" >&2; exit 1; }

# Rust core: the actor rule is a deterministic unit test.
(cd wirecore/crates/wire-profiles && /root/.cargo/bin/cargo test --offline automation_cannot) >/dev/null 2>&1 \
  || { echo "FAIL: Rust automation denial" >&2; exit 1; }
(cd wirecore/crates/wire-routing && /root/.cargo/bin/cargo test --offline no_silent_fallback) >/dev/null 2>&1 \
  || { echo "FAIL: Rust no-silent-fallback" >&2; exit 1; }

echo "failure denied-policy: ok"
