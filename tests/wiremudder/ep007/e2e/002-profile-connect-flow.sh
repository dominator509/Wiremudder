#!/usr/bin/env sh
# EP-007 M3 e2e test: full profile-routing connect flow through a real
# SOCKS5 relay (CI fixture mode, WM-SPEC-017-R09).
#   1. Character profile carries a routing default (WM-SPEC-010-R01).
#   2. Selected SOCKS5 route: traffic provably traverses the relay.
#   3. Relay failure: connection BLOCKS; never silently falls back to
#      direct (WM-SPEC-006-R06).
#   4. Direct/system route still connects: manual text gameplay is
#      preserved when optional routing is unavailable.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep007-m3-flow-$$
RELAY_LOG=$(mktemp)
ECHO_PID=""
RELAY_PID=""
trap 'rm -f "$HARNESS" "$RELAY_LOG"; [ -n "$ECHO_PID" ] && kill "$ECHO_PID" 2>/dev/null || true; [ -n "$RELAY_PID" ] && kill "$RELAY_PID" 2>/dev/null || true' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" \
  tests/wiremudder/ep007/harness/ep007_harness.cpp \
  src/wiremudder/profiles/character_profile_store.cpp \
  src/wiremudder/routing/route_profile_store.cpp \
  src/wiremudder/routing/router.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

# Controlled fixtures (SIMULATION: local test-only servers).
ECHO_PORT=$(( ( $$ % 20000 ) + 30000 ))
RELAY_PORT=$(( ECHO_PORT + 1 ))
python3 tests/wiremudder/ep007/fixtures/echo_server.py "$ECHO_PORT" >/dev/null 2>&1 &
ECHO_PID=$!
python3 tests/wiremudder/ep007/fixtures/socks5_relay.py "$RELAY_PORT" "$RELAY_LOG" >/dev/null 2>&1 &
RELAY_PID=$!
sleep 1

TOKEN="wm-egress-$$"

# 1. Traffic must traverse the relay.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" proxyflow \
  127.0.0.1 "$RELAY_PORT" 127.0.0.1 "$ECHO_PORT" "$TOKEN" >/dev/null 2>&1 \
  || { echo "FAIL: proxied connect through relay" >&2; exit 1; }
grep -q "127.0.0.1:$ECHO_PORT" "$RELAY_LOG" \
  || { echo "FAIL: relay did not see the target connect" >&2; cat "$RELAY_LOG" >&2; exit 1; }

# 2. Relay failure must block, not fall back.
kill "$RELAY_PID" 2>/dev/null || true
wait "$RELAY_PID" 2>/dev/null || true
RELAY_PID=""
sleep 1
if LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" proxyflow \
    127.0.0.1 "$RELAY_PORT" 127.0.0.1 "$ECHO_PORT" "$TOKEN" >/dev/null 2>&1; then
  echo "FAIL: selected route failure silently fell back" >&2
  exit 1
fi

# 3. Direct route still works (manual gameplay preserved).
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" router >/dev/null 2>&1 \
  || { echo "FAIL: direct gameplay path" >&2; exit 1; }

echo "e2e profile-connect-flow: ok"
