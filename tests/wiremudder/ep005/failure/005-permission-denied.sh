#!/usr/bin/env sh
# EP-005 M4 failure test: denied permission (SPEC-024-R02).
# The sidecar binds an owner-only socket (mode 0700). An unprivileged
# local user (nobody) must be denied; the owning user must connect.
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || { echo "FAIL: cargo build wirecore-runtime" >&2; exit 1; }
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || { echo "FAIL: sidecar binary missing" >&2; exit 1; }
SOCK=/tmp/wm-ep005-m4-perm-$$.sock
trap 'pkill -f "wirecore-runtime $SOCK" 2>/dev/null || true; rm -f "$SOCK"' EXIT

"$BIN" "$SOCK" >/tmp/wm-ep005-m4-perm.log 2>&1 &
sleep 0.5

# 1. Socket must be owner-only.
mode=$(stat -c "%a" "$SOCK")
[ "$mode" = "700" ] || { echo "FAIL: socket mode $mode, want 700" >&2; exit 1; }

# 2. Unprivileged user must be denied (python exits 0 when denied).
if command -v setpriv >/dev/null 2>&1; then
  if ! setpriv --reuid=nobody --regid=nogroup --clear-groups \
      python3 - "$SOCK" <<'PY'
import socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    s.connect(sys.argv[1])
except PermissionError:
    raise SystemExit(0)
raise SystemExit(1)
PY
  then
    echo "FAIL: unprivileged user connected to owner-only socket" >&2
    exit 1
  fi
fi

# 3. Owning user (root) must connect and handshake.
python3 - "$SOCK" <<'PY' || { echo "FAIL: owner connect" >&2; exit 1; }
import json, socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sys.argv[1]); s.settimeout(3)
hello = {"magic":"WMC1","version":1,"frame_id":"perm-0001","kind":"hello","payload":{"client":"perm","pid":1}}
s.sendall((json.dumps(hello)+"\n").encode())
buf = b''
while b'\n' not in buf: buf += s.recv(65536)
ack = json.loads(buf.split(b'\n')[0])
assert ack['kind'] == 'hello_ack' and ack['payload']['status'] == 'ok', ack
print('failure permission-denied: ok')
PY
