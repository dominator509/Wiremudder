#!/usr/bin/env sh
# EP-005 M4 security test: secrets redaction and file hygiene.
# A payload containing a fake secret must never appear in sidecar
# output; the socket must be owner-only; no world-writable files may
# exist under the bridge/crate boundaries.
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || { echo "FAIL: cargo build wirecore-runtime" >&2; exit 1; }
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || { echo "FAIL: sidecar binary missing" >&2; exit 1; }
SOCK=/tmp/wm-ep005-m4-sec-$$.sock
LOG=/tmp/wm-ep005-m4-sec.log
SECRET="WM-SECRET-PROBE-7f3a9c2d"
trap 'pkill -f "wirecore-runtime $SOCK" 2>/dev/null || true; rm -f "$SOCK" "$LOG"' EXIT

"$BIN" "$SOCK" >"$LOG" 2>&1 &
sleep 0.5

# 1. Send the secret inside a frame payload; the sidecar never echoes
#    payload content (only queue depth / accepted status).
python3 - "$SOCK" "$SECRET" <<'PY' || { echo "FAIL: secret exchange" >&2; exit 1; }
import json, socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sys.argv[1]); s.settimeout(3)
secret = sys.argv[2]
def send(obj):
    s.sendall((json.dumps(obj)+"\n").encode())
def readf():
    buf = b''
    while b'\n' not in buf: buf += s.recv(65536)
    line, _ = buf.split(b'\n', 1)
    return json.loads(line)
send({"magic":"WMC1","version":1,"frame_id":"hells-0001","kind":"hello","payload":{"client":"sec","pid":1}})
readf()
send({"magic":"WMC1","version":1,"frame_id":"secrt-0001","kind":"request","payload":{"token": secret, "op":"store"}})
r = readf()
assert r['payload'].get('accepted') is True, r
send({"magic":"WMC1","version":1,"frame_id":"shutd-0001","kind":"shutdown","payload":{}})
readf()
PY

# 2. Sidecar output must not contain the secret.
sleep 0.2
if grep -q "$SECRET" "$LOG"; then
  echo "FAIL: secret leaked into sidecar log" >&2; exit 1
fi

# 3. Socket must be owner-only.
mode=$(stat -c "%a" "$SOCK" 2>/dev/null || echo "gone")
[ "$mode" = "700" ] || { echo "FAIL: socket mode $mode, want 700" >&2; exit 1; }

# 4. No world-writable files under owned boundaries.
if find src/wiremudder/bridge wirecore/crates schemas/wiremudder/bridge \
     -type f -perm -0002 2>/dev/null | grep -q .; then
  echo "FAIL: world-writable file under owned boundary" >&2
  find src/wiremudder/bridge wirecore/crates schemas/wiremudder/bridge -type f -perm -0002 2>/dev/null >&2
  exit 1
fi
echo "security secrets-redaction: ok"
