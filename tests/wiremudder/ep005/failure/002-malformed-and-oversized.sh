#!/usr/bin/env sh
# EP-005 M4 failure test: malformed and oversized input rejection.
# Sends garbage, bad magic, wrong version, and >1 MiB frames to the
# REAL sidecar; it must reject each with an error/unsupported ack,
# stay alive, and continue serving valid frames.
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || { echo "FAIL: cargo build wirecore-runtime" >&2; exit 1; }
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || { echo "FAIL: sidecar binary missing" >&2; exit 1; }
SOCK=/tmp/wm-ep005-m4-mal-$$.sock
trap 'pkill -f "wirecore-runtime $SOCK" 2>/dev/null || true; rm -f "$SOCK"' EXIT

"$BIN" "$SOCK" >/tmp/wm-ep005-m4-mal.log 2>&1 &
sleep 0.5

python3 - "$SOCK" <<'PY' || { echo "FAIL: malformed/oversized handling" >&2; exit 1; }
import json, socket, sys, time
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
def send(raw):
    s.sendall(raw + b'\n' if not raw.endswith(b'\n') else raw)

# 1. Garbage line: sidecar must reply error and stay alive.
send(b'this is not json at all')
err = read_frame()
assert err['kind'] == 'response' and err['payload'].get('status') == 'error', err

# 2. Bad magic.
send(json.dumps({"magic":"XXXX","version":1,"frame_id":"badmg-0001","kind":"hello","payload":{}}).encode())
err = read_frame()
assert err['payload'].get('status') == 'error', err

# 3. Wrong version.
send(json.dumps({"magic":"WMC1","version":99,"frame_id":"badvr-0001","kind":"hello","payload":{}}).encode())
err = read_frame()
assert err['payload'].get('status') == 'error', err

# 4. Oversized frame (> 1 MiB): frame_id is over the size bound.
big = {"magic":"WMC1","version":1,"frame_id":"x"*(1024*1024+64),"kind":"hello","payload":{}}
send(json.dumps(big).encode())
err = read_frame()
assert err['payload'].get('status') == 'error', err

# 5. Sidecar still serves valid frames after all the abuse.
hello = {"magic":"WMC1","version":1,"frame_id":"valid-0001","kind":"hello","payload":{"client":"t","pid":1}}
send(json.dumps(hello).encode())
ack = read_frame()
assert ack['kind'] == 'hello_ack' and ack['payload']['status'] == 'ok', ack
print('failure malformed-oversized: ok')
PY
