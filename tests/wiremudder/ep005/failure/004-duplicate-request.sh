#!/usr/bin/env sh
# EP-005 M4 failure test: duplicate/replayed request handling.
# Sends the same frame_id twice to the REAL sidecar; the stateless
# frame protocol must accept both without corruption, and the sidecar
# must remain healthy (no replay amplification, no crash).
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || { echo "FAIL: cargo build wirecore-runtime" >&2; exit 1; }
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || { echo "FAIL: sidecar binary missing" >&2; exit 1; }
SOCK=/tmp/wm-ep005-m4-dup-$$.sock
trap 'pkill -f "wirecore-runtime $SOCK" 2>/dev/null || true; rm -f "$SOCK"' EXIT

"$BIN" "$SOCK" >/tmp/wm-ep005-m4-dup.log 2>&1 &
sleep 0.5

python3 - "$SOCK" <<'PY' || { echo "FAIL: duplicate request" >&2; exit 1; }
import json, socket, sys
sock = sys.argv[1]
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sock); s.settimeout(3)
buf = b''
def read_frame():
    global buf
    while b'\n' not in buf:
        chunk = s.recv(65536)
        if not chunk: raise RuntimeError('closed')
        buf += chunk
    line, buf = buf.split(b'\n', 1)
    return json.loads(line.decode())
def send(obj):
    s.sendall((json.dumps(obj) + "\n").encode())

send({"magic":"WMC1","version":1,"frame_id":"hello-0001","kind":"hello","payload":{"client":"dup","pid":1}})
read_frame()

# Same frame_id twice, back to back.
frame = {"magic":"WMC1","version":1,"frame_id":"dupf-0001","kind":"request","payload":{"op":"echo"}}
send(frame); r1 = read_frame()
send(frame); r2 = read_frame()
assert r1['frame_id'] == 'dupf-0001' and r2['frame_id'] == 'dupf-0001'
assert r1['payload'].get('accepted') is True and r2['payload'].get('accepted') is True
assert r1 != r2  # distinct queue entries, no replay dedup corruption

# Sidecar still healthy after replay.
send({"magic":"WMC1","version":1,"frame_id":"pingd-0001","kind":"ping","payload":{}})
pong = read_frame()
assert pong['kind'] == 'pong', pong
print('failure duplicate-request: ok')
PY
