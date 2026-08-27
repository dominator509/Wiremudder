#!/usr/bin/env sh
# EP-011 M3 e2e: full protocol connect flow against a controlled telnet
# fixture (SIMULATION: local test-only server).
#   1. Server offers GMCP/MSDP/ATCP (WILL).
#   2. Client boundary detects all three as negotiated (ready).
#   3. Server declines MSDP: detected as declined, never ready.
#   4. Manual text round-trips while protocol negotiation is active.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep011-m3-e2e-$$
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

PORT=$(( ( $$ % 20000 ) + 32000 ))
python3 tests/wiremudder/ep011/fixtures/telnet_server.py "$PORT" negotiate >/dev/null 2>&1 &
SRV_PID=$!
sleep 1

# 1. GMCP negotiated through the real socket.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" netflow \
  127.0.0.1 "$PORT" GMCP >/dev/null 2>&1 \
  || { echo "FAIL: GMCP not negotiated over socket" >&2; exit 1; }

# 2. ATCP negotiated through the real socket.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" netflow \
  127.0.0.1 "$PORT" ATCP >/dev/null 2>&1 \
  || { echo "FAIL: ATCP not negotiated over socket" >&2; exit 1; }

# 3. Manual gameplay round-trips while negotiation is active.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" manualflow \
  127.0.0.1 "$PORT" >/dev/null 2>&1 \
  || { echo "FAIL: manual gameplay echo while negotiating" >&2; exit 1; }

kill "$SRV_PID" 2>/dev/null || true
wait "$SRV_PID" 2>/dev/null || true
SRV_PID=""

# 4. Decline mode: server refuses MSDP, client must not report ready.
PORT2=$(( PORT + 1 ))
python3 tests/wiremudder/ep011/fixtures/telnet_server.py "$PORT2" decline >/dev/null 2>&1 &
SRV_PID=$!
sleep 1
OUT=$(LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" netflow 127.0.0.1 "$PORT2" MSDP 2>&1) && {
  echo "FAIL: declined MSDP reported as negotiated" >&2
  echo "$OUT" >&2
  exit 1
}
echo "$OUT" | grep -q "MSDP declined" || { echo "FAIL: MSDP not marked declined" >&2; echo "$OUT" >&2; exit 1; }

# 5. Manual gameplay still works after refused negotiation.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" manualflow \
  127.0.0.1 "$PORT2" >/dev/null 2>&1 \
  || { echo "FAIL: manual gameplay after declined negotiation" >&2; exit 1; }

echo "e2e protocol-connect-flow: ok"
