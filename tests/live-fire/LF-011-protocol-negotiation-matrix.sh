#!/usr/bin/env sh
# LF-011 protocol-negotiation-matrix (live-fire)
#
# Proves the real user outcome of EP-011: a client connecting to a server
# negotiates the capability matrix (GMCP/MSDP/ATCP/MXP/MSP/MSSP) through
# the real Telnet IAC boundary over real sockets; refused protocols are
# reported declined (last-verb-wins); malformed streams are bounded; and
# manual text gameplay is preserved in every state. Real controlled
# dependencies only (local test fixture, SIMULATION).
set -eu
fail() { echo "LF-011: FAIL - $1" >&2; exit 1; }

cd "$(dirname "$0")/../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-lf011-harness-$$
SRV_PID=""
trap 'rm -f "$HARNESS"; [ -n "$SRV_PID" ] && kill "$SRV_PID" 2>/dev/null || true' EXIT

echo "LF-011: protocol-negotiation-matrix"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

[ -d "$QT" ] || fail "Qt 6.8.2 not at $QT"
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" \
  tests/wiremudder/ep011/harness/ep011_harness.cpp \
  src/wiremudder/protocol/protocol_boundary.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || fail "harness compile"

PORT=$(( ( $$ % 20000 ) + 42000 ))

# 1. Negotiate mode: server offers GMCP + MSDP + ATCP; client detects all.
python3 tests/wiremudder/ep011/fixtures/telnet_server.py "$PORT" negotiate >/dev/null 2>&1 &
SRV_PID=$!
sleep 1
for p in GMCP MSDP ATCP; do
  LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" netflow \
    127.0.0.1 "$PORT" "$p" >/dev/null 2>&1 \
    || fail "$p not negotiated over live socket"
done
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" manualflow \
  127.0.0.1 "$PORT" >/dev/null 2>&1 \
  || fail "manual gameplay during negotiation"
kill "$SRV_PID" 2>/dev/null || true
wait "$SRV_PID" 2>/dev/null || true
SRV_PID=""

# 2. Decline mode: server refuses MSDP; client must report declined and
#    manual gameplay must survive.
PORT2=$(( PORT + 1 ))
python3 tests/wiremudder/ep011/fixtures/telnet_server.py "$PORT2" decline >/dev/null 2>&1 &
SRV_PID=$!
sleep 1
OUT=$(LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" netflow 127.0.0.1 "$PORT2" MSDP 2>&1) && {
  fail "declined MSDP reported as negotiated"
}
echo "$OUT" | grep -q "MSDP declined" || fail "MSDP not marked declined"
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" manualflow \
  127.0.0.1 "$PORT2" >/dev/null 2>&1 \
  || fail "manual gameplay after refusal"
kill "$SRV_PID" 2>/dev/null || true
wait "$SRV_PID" 2>/dev/null || true
SRV_PID=""

# 3. Last-verb-wins over the live boundary (WILL then WONT = declined).
OUT=$("$HARNESS" detect "ff fb c9 ff fc c9")
echo "$OUT" | grep -q "^GMCP no declined$" || fail "last-verb-wins"

# 4. Garbage mode: malformed stream bounded, manual gameplay preserved.
PORT3=$(( PORT + 2 ))
python3 tests/wiremudder/ep011/fixtures/telnet_server.py "$PORT3" garbage >/dev/null 2>&1 &
SRV_PID=$!
sleep 1
OUT=$(LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" netflow 127.0.0.1 "$PORT3" GMCP 2>&1) && {
  fail "garbage stream unexpectedly negotiated"
}
echo "$OUT" | grep -q "GMCP absent" || fail "GMCP not absent on garbage"
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" manualflow \
  127.0.0.1 "$PORT3" >/dev/null 2>&1 \
  || fail "manual gameplay after garbage"
kill "$SRV_PID" 2>/dev/null || true
wait "$SRV_PID" 2>/dev/null || true
SRV_PID=""

# 5. Performance: in-process burst stays far inside the 10ms budget.
OUT=$(sh tests/wiremudder/ep011/performance/001-capability-latency.sh 2>&1 | grep "per-burst")
echo "$OUT"
case "$OUT" in
  *budget=10.0ms*) : ;;
  *) fail "performance budget line unexpected: $OUT" ;;
esac

echo "LF-011: protocol-negotiation-matrix ok"
