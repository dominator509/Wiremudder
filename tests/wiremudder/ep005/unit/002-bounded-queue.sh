#!/usr/bin/env sh
# Unit test: bounded queue degrades on overflow (P2-P4 drop, no P0
# backpressure) and reports dropped counts.
set -eu
python3 - <<'PY' || { echo "FAIL: bounded queue" >&2; exit 1; }
import json, os, socket, subprocess, time
sock = f'/tmp/wm-ep005-q-{int(time.time()*1000)}.sock'
proc = subprocess.Popen(['wirecore/target/release/wirecore-runtime', sock],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
buf = b''
def read_frame(s):
    global buf
    while b'\n' not in buf:
        chunk = s.recv(65536)
        if not chunk:
            raise RuntimeError('connection closed')
        buf += chunk
    line, buf = buf.split(b'\n', 1)
    return json.loads(line.decode())
try:
    time.sleep(1.0)
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(sock); s.settimeout(5)
    def send(kind, fid, payload):
        frame = {"magic": "WMC1", "version": 1, "frame_id": fid, "kind": kind, "payload": payload}
        s.sendall((json.dumps(frame) + "\n").encode())
        return read_frame(s)
    send("hello", "q-00", {"client": "unit"})
    # Push 300 requests through a 256-capacity queue: overflow must not block.
    for i in range(300):
        resp = send("request", f"q-{i:04d}", {"i": i})
        assert resp["payload"]["accepted"] is True, resp
    snap = send("snapshot", "q-end", {})
    assert snap["payload"]["dropped"] >= 44, snap  # 300 - 256 = 44 dropped
    print(f'unit bounded-queue: ok dropped={snap["payload"]["dropped"]}')
finally:
    try:
        s.close()
    except Exception:
        pass
    proc.terminate()
    try:
        proc.wait(timeout=5)
    except Exception:
        proc.kill()
    try: os.unlink(sock)
    except OSError: pass
PY
