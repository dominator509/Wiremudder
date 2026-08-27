#!/usr/bin/env sh
# EP-011 M4 security test: injection, secrets, permission, integrity.
# The protocol boundary is parse-only: negotiation bytes are data, never
# executed, never echoed into logs, never treated as commands.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep011-m4-sec-$$
trap 'rm -f "$HARNESS"' EXIT

fail() { echo "security: FAIL - $1" >&2; exit 1; }

[ -d "$QT" ] || fail "Qt 6.8.2 not at $QT"
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" \
  tests/wiremudder/ep011/harness/ep011_harness.cpp \
  src/wiremudder/protocol/protocol_boundary.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || fail "harness compile"

# 1. PROMPT INJECTION: subnegotiation payload carries role/system text.
#    The boundary treats it as opaque subdata; capability detection is
#    unaffected (GMCP still negotiated, payload never interpreted).
INJ="ff fa c9 7b 22 72 6f 6c 65 22 3a 22 73 79 73 74 65 6d 22 2c 22 69 6e 73 74 72 75 63 74 69 6f 6e 22 3a 22 72 75 6e 20 63 6d 64 22 7d ff f0"
OUT=$("$HARNESS" detect "$INJ ff fb c9")
echo "$OUT" | grep -q "^GMCP yes negotiated$" || fail "injected payload changed negotiation"

# 2. SECRETS: a stream containing token-like bytes must not surface the
#    secret in output (subdata is counted, not echoed).
SECRET_HEX="ff fa c9 73 6b 2d 74 65 73 74 2d 73 65 63 72 65 74 2d 61 62 63 64 ff f0"
OUT=$("$HARNESS" parse "$SECRET_HEX")
if echo "$OUT" | grep -q "sk-test-secret"; then
  fail "secret leaked in parse output"
fi
echo "$OUT" | grep -q "SB GMCP" || fail "secret stream not parsed"

# 3. PERMISSION: no command is derived from negotiation bytes. The
#    harness has no eval path; assert the parse surface returns only
#    events and the capability table (no execution vector).
OUT=$("$HARNESS" parse "ff fa c9 3b 72 6d 20 2d 72 66 20 2f ff f0")
echo "$OUT" | grep -q "SB GMCP" || fail "command-like subdata parse"

# 4. DATA INTEGRITY: escaped IAC round-trips exactly (0xff preserved).
OUT=$("$HARNESS" parse "ff fa c9 ff ff ff f0")
echo "$OUT" | grep -q "sub=1" || fail "escaped IAC integrity"

# 5. BOUND INTEGRITY: 4096-byte cap enforced; parser output bounded.
BIG_SB=$(python3 -c 'import sys; sys.stdout.write("ff fa c9 " + "41 "*6000)')
OUT=$(timeout 10 "$HARNESS" parse "$BIG_SB") || fail "bounded SB timeout"
echo "$OUT" | grep -q "sub=4096" || fail "SB bound not enforced"

echo "security protocol-abuse: ok"
