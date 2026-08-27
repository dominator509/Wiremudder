#!/usr/bin/env sh
# Unit test: WireCore sidecar speaks the versioned handshake and
# ping/pong health over a real Unix domain socket.
set -eu
BIN=wirecore/target/release/wirecore-runtime
SOCK=/tmp/wm-ep005-unit-$$.sock
[ -x "$BIN" ] || { echo "SKIP: wirecore not built" >&2; exit 0; }
"$BIN" "$SOCK" >/tmp/wm-ep005-unit.log 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null || true; rm -f "$SOCK"' EXIT
sleep 0.5
python3 - "$SOCK" <<'PY' || { echo "FAIL: handshake" >&2; exit 1; }
import json, socket, sys, time
sock = sys.argv[1]
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sock)
s.settimeout(3)
buf = b''
def read_frame():
    global buf
    while b'\n' not in buf:
        chunk = s.recv(65536)
        if not chunk:
            raise RuntimeError('closed')
        buf += chunk
    line, buf = buf.split(b'\n', 1)
    return json.loads(line.decode())
hello = {"magic": "WMC1", "version": 1, "frame_id": "unit-0001", "kind": "hello", "payload": {"client": "unit", "pid": 1}}
s.sendall((json.dumps(hello) + "\n").encode())
ack = read_frame()
assert ack["magic"] == "WMC1" and ack["kind"] == "hello_ack", ack
assert ack["payload"]["status"] == "ok", ack
ping = {"magic": "WMC1", "version": 1, "frame_id": "unit-0002", "kind": "ping", "payload": {}}
s.sendall((json.dumps(ping) + "\n").encode())
pong = read_frame()
assert pong["kind"] == "pong", pong
print("unit wirecore-handshake: ok")
PY
