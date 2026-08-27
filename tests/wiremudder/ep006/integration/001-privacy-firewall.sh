#!/usr/bin/env sh
# EP-006 M3 integration test: C++ PrivacyFirewall invariants.
# Real Qt implementation (privacy_firewall.cpp): lockdown denies by
# default, overrides require user visibility + consent, routing is
# lawful-only, redaction is deterministic.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep006-m3-fw-harness-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I/usr/include/qt6keychain -I"$PWD" \
  tests/wiremudder/ep006/harness/privacy_harness.cpp \
  src/wiremudder/privacy/privacy_firewall.cpp \
  src/wiremudder/privacy/secret_vault.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -lqt6keychain \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" firewall 2>&1 \
  || { echo "FAIL: firewall harness" >&2; exit 1; }
echo "integration privacy-firewall: ok"
