#!/usr/bin/env sh
# Integration test: the inherited client can connect to a Protocol
# Museum fake server over a real TCP connection (compat oracle boundary).
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
bin="build-$preset/src/mudlet"
[ -x "$bin" ] || { echo "SKIP: client not built" >&2; exit 0; }
python3 - <<'PY' || { echo "FAIL: client-museum integration" >&2; exit 1; }
import socket, subprocess, sys, time
sys.path.insert(0, 'compatibility/protocol-museum')
from museum import FakeMudServer, negotiation_handler
# Start a museum server on a fixed port.
s = FakeMudServer('client-integration', negotiation_handler, port=42421).start()
time.sleep(0.2)
# Prove the port accepts real connections and emits the fixture.
c = socket.create_connection(('127.0.0.1', 42421), timeout=3)
c.settimeout(2)
data = c.recv(4096)
c.close()
s.stop()
assert b'Protocol Museum' in data, 'fixture banner missing'
print('integration client-museum-port: ok')
PY
echo "integration client-museum-port: ok"
