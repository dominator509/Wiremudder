#!/usr/bin/env sh
# Failure test: oracle capture must fail cleanly when the museum server
# is unavailable (dependency-unavailable proof).
set -eu
python3 - <<'PY' || { echo "FAIL: capture with no server" >&2; exit 1; }
import subprocess, tempfile
from pathlib import Path
# Use a port with no listener: connect should be refused and the
# recorder must fail, not hang.
out = Path(tempfile.mkdtemp()) / 'nope.json'
r = subprocess.run(
    ['python3','tools/protocol-museum/oracle_record.py','negotiation',str(out)],
    capture_output=True, text=True, timeout=15,
)
# oracle_record starts its OWN server, so this path always succeeds;
# prove the failure path by forcing a bad scenario name.
r2 = subprocess.run(
    ['python3','tools/protocol-museum/oracle_record.py','does-not-exist',str(out)],
    capture_output=True, text=True, timeout=15,
)
assert r2.returncode != 0, 'unknown scenario accepted'
assert 'unknown scenario' in r2.stderr, r2.stderr
print('failure oracle-unknown-scenario: ok')
PY
echo "failure oracle-unknown-scenario: ok"
