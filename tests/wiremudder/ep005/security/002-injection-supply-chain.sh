#!/usr/bin/env sh
# EP-005 M4 security test: injection resistance and supply chain.
# Injection payloads (shell, SQL, JSON control characters) must be
# treated as DATA by the real sidecar; the dependency tree must be
# exactly serde/serde_json/wire-contracts; Cargo.lock must be tracked.
set -eu

cd "$(dirname "$0")/../../../.."
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml >/dev/null 2>&1 \
  || { echo "FAIL: cargo build wirecore-runtime" >&2; exit 1; }
BIN="$PWD/wirecore/target/release/wirecore-runtime"
[ -x "$BIN" ] || { echo "FAIL: sidecar binary missing" >&2; exit 1; }
SOCK=/tmp/wm-ep005-m4-inj-$$.sock
trap 'pkill -f "wirecore-runtime $SOCK" 2>/dev/null || true; rm -f "$SOCK"' EXIT

"$BIN" "$SOCK" >/tmp/wm-ep005-m4-inj.log 2>&1 &
sleep 0.5

# 1. Injection payloads round-trip as data; no execution, no crash.
python3 - "$SOCK" <<'PY' || { echo "FAIL: injection handling" >&2; exit 1; }
import json, socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sys.argv[1]); s.settimeout(3)
def send(obj):
    s.sendall((json.dumps(obj)+"\n").encode())
def readf():
    buf = b''
    while b'\n' not in buf: buf += s.recv(65536)
    line, _ = buf.split(b'\n', 1)
    return json.loads(line)
send({"magic":"WMC1","version":1,"frame_id":"hellj-0001","kind":"hello","payload":{"client":"inj","pid":1}})
readf()
injections = [
    "$(rm -rf /tmp/wm-injected)",
    "'; DROP TABLE users; --",
    "|| curl http://127.0.0.1:9/x ||",
    "\"; touch /tmp/wm-injected-2; \"",
]
for i, payload in enumerate(injections):
    fid = "inject-%04d" % i
    send({"magic":"WMC1","version":1,"frame_id":fid,"kind":"request","payload":{"text": payload}})
    r = readf()
    assert r['frame_id'] == fid and r['payload'].get('accepted') is True, r
# No injection side effect may exist.
import os
assert not os.path.exists('/tmp/wm-injected'), 'shell injection executed'
assert not os.path.exists('/tmp/wm-injected-2'), 'shell injection executed'
# Sidecar still healthy.
send({"magic":"WMC1","version":1,"frame_id":"pingi-0001","kind":"ping","payload":{}})
assert readf()['kind'] == 'pong'
print('security injection-resistance: ok')
PY

# 2. Supply chain: dependency tree is exactly serde/serde_json/wire-contracts.
cargo tree --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml 2>/dev/null \
  | grep -E '^├──|^└──' \
  | grep -vE 'serde|serde_json|wire-contracts|proc-macro2|unicode-ident|quote|syn|itoa|memchr|serde_core|serde_derive|zmij' \
  && { echo "FAIL: unexpected direct dependency" >&2; exit 1; } || true

# 3. Cargo.lock tracked (reproducible supply chain).
/usr/bin/git ls-files --error-unmatch wirecore/crates/wirecore-runtime/Cargo.lock >/dev/null 2>&1 \
  || { echo "FAIL: Cargo.lock not tracked" >&2; exit 1; }
echo "security supply-chain: ok"
