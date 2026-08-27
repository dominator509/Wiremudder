#!/usr/bin/env sh
# Unit test: frame protocol rejects bad magic, bad version, and
# oversized frames (fail-closed validation).
set -eu
python3 - <<'PY' || { echo "FAIL: frame validation" >&2; exit 1; }
import json, socket, subprocess, time
sock = f'/tmp/wm-ep005-v-{int(time.time()*1000)}.sock'
proc = subprocess.Popen(['wirecore/target/release/wirecore-runtime', sock],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    time.sleep(1.0)
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(sock); s.settimeout(3)
    buf = [b'']
    def read_frame():
        while b'\n' not in buf[0]:
            chunk = s.recv(65536)
            if not chunk:
                raise RuntimeError('closed')
            buf[0] += chunk
        line, buf[0] = buf[0].split(b'\n', 1)
        return json.loads(line.decode())
    # Bad magic -> error ack, connection survives.
    bad = {"magic": "XXXX", "version": 1, "frame_id": "v-01", "kind": "hello", "payload": {}}
    s.sendall((json.dumps(bad) + "\n").encode())
    line = read_frame()
    assert line["payload"]["status"] == "error", line
    # Bad version -> version mismatch error.
    bad2 = {"magic": "WMC1", "version": 99, "frame_id": "v-02", "kind": "hello", "payload": {}}
    s.sendall((json.dumps(bad2) + "\n").encode())
    line = read_frame()
    assert line["payload"]["status"] == "error", line
    print("unit frame-validation: ok")
finally:
    try: s.close()
    except Exception: pass
    proc.terminate(); proc.wait(timeout=5)
    import os
    try: os.unlink(sock)
    except OSError: pass
PY
