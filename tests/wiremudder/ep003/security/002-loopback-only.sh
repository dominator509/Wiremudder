#!/usr/bin/env sh
# Security test: museum servers bind loopback only (no external exposure).
set -eu
python3 - <<'PY' || { echo "FAIL: loopback binding" >&2; exit 1; }
import socket, sys, time
sys.path.insert(0, 'compatibility/protocol-museum')
from museum import FakeMudServer, negotiation_handler
s = FakeMudServer('bind-test', negotiation_handler).start()
time.sleep(0.2)
# The bound address must be 127.0.0.1.
addr = s.sock.getsockname()
assert addr[0] == '127.0.0.1', f'bound to {addr[0]}'
s.stop()
print(f'security loopback-only: ok port={addr[1]}')
PY
echo "security loopback-only: ok"
