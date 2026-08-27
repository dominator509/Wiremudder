#!/usr/bin/env sh
# EP-006 M3 integration test: Secrets Vault with QtKeychain.
# Real SecretVaultQt implementation: store/retrieve/remove, duplicate
# rejection, leak redaction, and an honest OS-backend availability
# probe (falls back to the documented local-only store headless).
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep006-m3-vault-harness-$$
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

LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" vault 2>&1 \
  || { echo "FAIL: vault harness" >&2; exit 1; }
echo "integration secrets-vault: ok"
