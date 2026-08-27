#!/usr/bin/env sh
# EP-011 M3 integration: protocol boundary parses real IAC byte streams
# and detects capabilities (WM-FEAT-0022..0036).
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep011-m3-int-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" \
  tests/wiremudder/ep011/harness/ep011_harness.cpp \
  src/wiremudder/protocol/protocol_boundary.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

# 1. GMCP negotiation: IAC WILL GMCP = ff fb c9.
OUT=$("$HARNESS" parse "ff fb c9")
echo "$OUT" | grep -q "WILL GMCP" || { echo "FAIL: parse WILL GMCP" >&2; echo "$OUT" >&2; exit 1; }

# 2. MSDP: ff fb 45.
OUT=$("$HARNESS" parse "ff fb 45")
echo "$OUT" | grep -q "WILL MSDP" || { echo "FAIL: parse WILL MSDP" >&2; echo "$OUT" >&2; exit 1; }

# 3. ATCP: ff fb c8.
OUT=$("$HARNESS" parse "ff fb c8")
echo "$OUT" | grep -q "WILL ATCP" || { echo "FAIL: parse WILL ATCP" >&2; echo "$OUT" >&2; exit 1; }

# 4. DONT MSDP = ff fe 45.
OUT=$("$HARNESS" parse "ff fe 45")
echo "$OUT" | grep -q "DONT MSDP" || { echo "FAIL: parse DONT MSDP" >&2; echo "$OUT" >&2; exit 1; }

# 5. Subnegotiation: IAC SB GMCP <json> IAC SE is parsed with payload.
OUT=$("$HARNESS" parse "ff fa c9 7b 22 6b 22 3a 22 76 22 7d ff f0")
echo "$OUT" | grep -q "SB GMCP" || { echo "FAIL: parse SB GMCP" >&2; echo "$OUT" >&2; exit 1; }

# 6. Escaped IAC inside subnegotiation must not terminate early.
#    ff fa c9 ff ff ff f0 -> subdata contains one 0xff then SE.
OUT=$("$HARNESS" parse "ff fa c9 ff ff ff f0")
echo "$OUT" | grep -q "sub=1" || { echo "FAIL: escaped IAC handling" >&2; echo "$OUT" >&2; exit 1; }

# 7. Unterminated SB is bounded at 4096, does not hang or crash.
OUT=$("$HARNESS" parse "$(python3 -c 'print("ff fa c9 " + "41 "*5000)')")
echo "$OUT" | grep -q "SB GMCP" || { echo "FAIL: bounded SB" >&2; echo "$OUT" >&2; exit 1; }

# 8. Plain text with no IAC yields zero events.
OUT=$("$HARNESS" parse "68 65 6c 6c 6f")
echo "$OUT" | grep -q "events=0" || { echo "FAIL: plain text events" >&2; echo "$OUT" >&2; exit 1; }

# 9. Capability detection: negotiated / declined / absent / research.
OUT=$("$HARNESS" detect "ff fb c9 ff fc 45")
echo "$OUT" | grep -q "^GMCP yes negotiated$" || { echo "FAIL: GMCP negotiated" >&2; echo "$OUT" >&2; exit 1; }
echo "$OUT" | grep -q "^MSDP no declined$" || { echo "FAIL: MSDP declined" >&2; echo "$OUT" >&2; exit 1; }
echo "$OUT" | grep -q "^MXP no absent$" || { echo "FAIL: MXP absent" >&2; echo "$OUT" >&2; exit 1; }
echo "$OUT" | grep -q "^MCP no research$" || { echo "FAIL: MCP research" >&2; echo "$OUT" >&2; exit 1; }

echo "integration boundary-net: ok"
