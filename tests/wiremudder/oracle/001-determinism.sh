#!/usr/bin/env sh
# Oracle test: recording the same museum scenario twice yields the same
# sanitized event stream (determinism invariant, SPEC-019-R04).
set -eu
python3 - <<'PY' || { echo "FAIL: oracle determinism" >&2; exit 1; }
import json, subprocess, tempfile
from pathlib import Path
tmp = Path(tempfile.mkdtemp())
a = tmp / 'a.json'
b = tmp / 'b.json'
subprocess.run(['python3', 'tools/protocol-museum/oracle_record.py', 'text-stream', str(a)], check=True)
subprocess.run(['python3', 'tools/protocol-museum/oracle_record.py', 'text-stream', str(b)], check=True)
da = json.loads(a.read_text(encoding='utf-8'))
db = json.loads(b.read_text(encoding='utf-8'))
# The deterministic lines must match in content and count (session ids
# and timestamps differ by design).
la = [e.get('line') for e in da['events']]
lb = [e.get('line') for e in db['events']]
assert len(la) == len(lb) and la == lb, f'determinism drift: {la} vs {lb}'
print(f'oracle determinism: ok lines={len(la)}')
PY
echo "oracle determinism: ok"
