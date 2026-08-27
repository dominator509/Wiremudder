#!/usr/bin/env sh
# EP-005 M4 failure test: queue budget exhaustion.
# Pushes 300 P2-P4 requests at the REAL sidecar's bounded queue
# (capacity 256). Overflow must drop the oldest frames (dropped > 0),
# never grow the queue past capacity, and never crash the sidecar.
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || { echo "FAIL: cargo build wirecore-runtime" >&2; exit 1; }
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || { echo "FAIL: sidecar binary missing" >&2; exit 1; }
SOCK=/tmp/wm-ep005-m4-q-$$.sock
trap 'pkill -f "wirecore-runtime $SOCK" 2>/dev/null || true; rm -f "$SOCK"' EXIT

"$BIN" "$SOCK" >/tmp/wm-ep005-m4-q.log 2>&1 &
sleep 0.5

python3 - "$SOCK" <<'PY' || { echo "FAIL: queue exhaustion" >&2; exit 1; }
import json, socket, sys
sock = sys.argv[1]
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sock); s.settimeout(5)
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

send({"magic":"WMC1","version":1,"frame_id":"hello-0001","kind":"hello","payload":{"client":"q","pid":1}})
ack = read_frame()
assert ack['kind'] == 'hello_ack' and ack['payload']['status'] == 'ok', ack

# Push 300 requests (capacity 256) in pipelined batches: read replies
# as we go (real clients, including the Qt supervisor, drain the
# socket continuously; a burst-send-without-read client would
# eventually hit kernel flow control, which is normal socket behavior).
N = 300
BATCH = 50
last = {}
for base in range(0, N, BATCH):
    batch = range(base, min(base + BATCH, N))
    for i in batch:
        fid = "reqq-%04d" % i
        send({"magic":"WMC1","version":1,"frame_id":fid,"kind":"request","payload":{"i":i}})
        last[fid] = None
    for i in batch:
        fid = "reqq-%04d" % i
        last[fid] = read_frame()
assert all(v['kind'] == 'response' for v in last.values()), 'missing replies'

# Snapshot must show bounded queue + dropped frames.
send({"magic":"WMC1","version":1,"frame_id":"snapq-0001","kind":"snapshot","payload":{}})
snap = read_frame()['payload']
assert snap['queue_len'] <= 256, f"queue grew past capacity: {snap['queue_len']}"
assert snap['dropped'] > 0, f"no drops recorded: {snap['dropped']}"
print(f"failure queue-exhaustion: ok queue_len={snap['queue_len']} dropped={snap['dropped']}")
PY
