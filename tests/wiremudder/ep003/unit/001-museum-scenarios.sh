#!/usr/bin/env sh
# Unit test: protocol museum fake servers emit deterministic text and
# negotiation fixtures over a real TCP connection.
set -eu
python3 - <<'PY' || { echo "FAIL: museum scenarios" >&2; exit 1; }
import socket, sys, time
sys.path.insert(0, 'compatibility/protocol-museum')
from museum import FakeMudServer, negotiation_handler, text_stream_handler, malformed_handler, latency_handler, disconnect_handler, available_scenarios
assert set(available_scenarios()) >= {'negotiation','text-stream','malformed','latency','disconnect'}
# negotiation scenario
s = FakeMudServer('test-negotiation', negotiation_handler).start()
c = socket.create_connection(('127.0.0.1', s.port), timeout=3); c.settimeout(2)
data = b''
deadline = time.time() + 2
while time.time() < deadline:
    try:
        chunk = c.recv(4096)
    except socket.timeout:
        break
    if not chunk: break
    data += chunk
c.close(); s.stop()
assert b'\xff\xfb\x01' in data, 'missing IAC WILL ECHO'
assert b'Protocol Museum' in data, 'missing banner'
print('unit museum-scenarios: ok')
PY
echo "unit museum-scenarios: ok"
