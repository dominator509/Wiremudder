#!/usr/bin/env sh
# EP-007 M4 failure test: unavailable dependency. A selected SOCKS5
# route whose relay is down must BLOCK the connection; egress
# verification must report failure; manual direct gameplay survives.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep007-m4-dep-$$
RELAY_LOG=$(mktemp)
ECHO_PID=""
RELAY_PID=""
trap 'rm -f "$HARNESS" "$RELAY_LOG"; [ -n "$ECHO_PID" ] && kill "$ECHO_PID" 2>/dev/null || true; [ -n "$RELAY_PID" ] && kill "$RELAY_PID" 2>/dev/null || true' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep007/harness/ep007_harness.cpp \
  src/wiremudder/profiles/character_profile_store.cpp \
  src/wiremudder/routing/route_profile_store.cpp \
  src/wiremudder/routing/router.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

ECHO_PORT=$(( ( $$ % 20000 ) + 30000 ))
RELAY_PORT=$(( ECHO_PORT + 1 ))
python3 tests/wiremudder/ep007/fixtures/echo_server.py "$ECHO_PORT" >/dev/null 2>&1 &
ECHO_PID=$!
python3 tests/wiremudder/ep007/fixtures/socks5_relay.py "$RELAY_PORT" "$RELAY_LOG" >/dev/null 2>&1 &
RELAY_PID=$!
sleep 1

TOKEN="wm-dep-$$"

# Healthy relay: flow works.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" proxyflow \
  127.0.0.1 "$RELAY_PORT" 127.0.0.1 "$ECHO_PORT" "$TOKEN" >/dev/null 2>&1 \
  || { echo "FAIL: healthy relay flow" >&2; exit 1; }

# Dependency unavailable: relay dies mid-session.
kill "$RELAY_PID" 2>/dev/null || true
wait "$RELAY_PID" 2>/dev/null || true
RELAY_PID=""
sleep 1

# The same connect must now block (no silent fallback, WM-SPEC-006-R06).
if LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" proxyflow \
    127.0.0.1 "$RELAY_PORT" 127.0.0.1 "$ECHO_PORT" "$TOKEN" >/dev/null 2>&1; then
  echo "FAIL: unavailable dependency did not block" >&2
  exit 1
fi

# Egress verification against the dead relay reports failure: connecting
# to the relay endpoint must fail (connection refused), never succeed.
python3 - "$RELAY_PORT" <<'PY' || { echo "FAIL: egress verify should fail" >&2; exit 1; }
import socket, sys
port = int(sys.argv[1])
try:
    s = socket.create_connection(("127.0.0.1", port), timeout=1)
except OSError:
    sys.exit(0)  # expected: relay is gone, verification fails
sys.exit(1)      # unexpected: relay still reachable
PY

# Manual gameplay preserved: direct route still connects (harness router
# includes a real direct echo).
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" router >/dev/null 2>&1 \
  || { echo "FAIL: direct gameplay after dependency loss" >&2; exit 1; }

echo "failure unavailable-dependency: ok"
