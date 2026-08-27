#!/usr/bin/env sh
# EP-005 M4 performance test: bounded queue latency and throughput.
# Drives 2000 requests through the REAL sidecar's bounded queue,
# records the latency distribution and hardware profile as raw
# evidence, and asserts generous local-socket thresholds (SPEC-004-R11,
# R12: distributions + hardware + workload + raw evidence).
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || { echo "FAIL: cargo build wirecore-runtime" >&2; exit 1; }
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || { echo "FAIL: sidecar binary missing" >&2; exit 1; }
SOCK=/tmp/wm-ep005-m4-perf-$$.sock
EVIDENCE=.agent/state/evidence/EP-005/M4/performance-001.json
mkdir -p .agent/state/evidence/EP-005/M4
trap 'pkill -f "wirecore-runtime $SOCK" 2>/dev/null || true; rm -f "$SOCK"' EXIT

"$BIN" "$SOCK" >/tmp/wm-ep005-m4-perf.log 2>&1 &
sleep 0.5

python3 - "$SOCK" "$EVIDENCE" <<'PY' || { echo "FAIL: performance" >&2; exit 1; }
import json, os, platform, socket, sys, time
sock = sys.argv[1]; ev_path = sys.argv[2]
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sock); s.settimeout(10)
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

send({"magic":"WMC1","version":1,"frame_id":"hello-0001","kind":"hello","payload":{"client":"perf","pid":1}})
read_frame()

N = 2000
lat = []
t0 = time.perf_counter()
for i in range(N):
    fid = "perfr-%04d" % i
    send({"magic":"WMC1","version":1,"frame_id":fid,"kind":"request","payload":{"i":i}})
    a = time.perf_counter()
    r = read_frame()
    lat.append((time.perf_counter() - a) * 1000.0)
    assert r['frame_id'] == fid, r
wall = time.perf_counter() - t0

# Snapshot for queue depth + drops.
send({"magic":"WMC1","version":1,"frame_id":"snapp-0001","kind":"snapshot","payload":{}})
snap = read_frame()['payload']

lat.sort()
def pct(p):
    return lat[min(len(lat)-1, int(len(lat)*p))]
p50, p95, p99 = pct(0.50), pct(0.95), pct(0.99)
throughput = N / wall

hw = {
    "uname": platform.uname()._asdict(),
    "cpu_count": os.cpu_count(),
    "python": platform.python_version(),
}
ev = {
    "node": "EP-005", "milestone": "M4", "fixture": "queue-latency",
    "hardware": hw,
    "workload": {"requests": N, "queue_capacity": 256, "frame_size_bytes": 128},
    "distributions_ms": {"p50": round(p50, 3), "p95": round(p95, 3), "p99": round(p99, 3),
                         "min": round(min(lat), 3), "max": round(max(lat), 3)},
    "throughput_req_per_s": round(throughput, 1),
    "wall_seconds": round(wall, 3),
    "snapshot": snap,
    "thresholds": {"p95_ms_lt": 20.0, "min_throughput_req_per_s": 500.0, "queue_len_le": 256},
    "observed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
}
with open(ev_path, "w", encoding="utf-8") as f:
    json.dump(ev, f, indent=2)

assert p95 < 20.0, f"p95 {p95:.3f} ms exceeds 20 ms budget"
assert throughput > 500.0, f"throughput {throughput:.1f} req/s below 500"
assert snap['queue_len'] <= 256, f"queue_len {snap['queue_len']} over capacity"
print(f"performance queue-latency: ok p50={p50:.3f}ms p95={p95:.3f}ms p99={p99:.3f}ms "
      f"tput={throughput:.0f}/s queue_len={snap['queue_len']}")
PY
