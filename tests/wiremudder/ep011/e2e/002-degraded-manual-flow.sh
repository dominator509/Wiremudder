#!/usr/bin/env sh
# EP-011 M3 e2e: degraded protocol surface preserves manual text gameplay.
# A server sending malformed/garbage Telnet bytes must not break the
# manual command path (WM-SPEC-006 optional-failure behavior).
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep011-m3-deg-$$
SRV_PID=""
trap 'rm -f "$HARNESS"; [ -n "$SRV_PID" ] && kill "$SRV_PID" 2>/dev/null || true' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" \
  tests/wiremudder/ep011/harness/ep011_harness.cpp \
  src/wiremudder/protocol/protocol_boundary.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

PORT=$(( ( $$ % 20000 ) + 34000 ))
python3 tests/wiremudder/ep011/fixtures/telnet_server.py "$PORT" garbage >/dev/null 2>&1 &
SRV_PID=$!
sleep 1

# 1. Boundary parses the garbage stream without hanging or crashing.
OUT=$(LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" netflow 127.0.0.1 "$PORT" GMCP 2>&1) && {
  echo "FAIL: garbage stream unexpectedly negotiated GMCP" >&2
  echo "$OUT" >&2
  exit 1
}
echo "$OUT" | grep -q "GMCP absent" || { echo "FAIL: GMCP not absent on garbage" >&2; echo "$OUT" >&2; exit 1; }

# 2. Manual text gameplay still round-trips after the garbage stream.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" manualflow \
  127.0.0.1 "$PORT" >/dev/null 2>&1 \
  || { echo "FAIL: manual gameplay broken by garbage protocol bytes" >&2; exit 1; }

# 3. Unterminated SB (4096-byte runaway) is bounded: boundary returns
#    instead of consuming the stream forever.
OUT=$(LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" parse "ff fa c9 $(python3 -c 'print("41 "*5000)')")
echo "$OUT" | grep -q "SB GMCP" || { echo "FAIL: runaway SB not bounded" >&2; echo "$OUT" >&2; exit 1; }

echo "e2e degraded-manual-flow: ok"
