#!/usr/bin/env sh
# EP-006 M4 security test: secrets never leak through any surface.
# The vault harness output must never contain stored secret values;
# neither crate may contain log macros that could print values.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep006-m4-sec-harness-$$
OUT=/tmp/wm-ep006-m4-sec.out
trap 'rm -f "$HARNESS" "$OUT"' EXIT

# 1. No log macros in the secrets/privacy crates.
if grep -rn "println!\|eprintln!\|dbg!" wirecore/crates/wire-secrets/src/ wirecore/crates/wire-privacy/src/; then
  echo "FAIL: log macro in crate source" >&2; exit 1
fi

# 2. C++ vault harness output must not contain stored values.
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
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" vault > "$OUT" 2>&1 \
  || { echo "FAIL: vault harness" >&2; exit 1; }
if grep -q "hunter2\|tok-1234" "$OUT"; then
  echo "FAIL: secret value leaked to harness output" >&2; exit 1
fi

# 3. Firewall redaction survives in harness output (no raw tokens).
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" firewall > "$OUT" 2>&1 \
  || { echo "FAIL: firewall harness" >&2; exit 1; }
if grep -q "sk-abc...mnop" "$OUT"; then
  echo "FAIL: raw token leaked to harness output" >&2; exit 1
fi
echo "security secrets-never-leak: ok"
