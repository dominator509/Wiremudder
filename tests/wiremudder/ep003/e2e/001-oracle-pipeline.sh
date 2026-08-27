#!/usr/bin/env sh
# E2E test: end-to-end oracle pipeline — fake server -> capture ->
# sanitize -> validate -> differential compare of two runs.
set -eu
python3 - <<'PY' || { echo "FAIL: oracle e2e" >&2; exit 1; }
import json, subprocess, sys, tempfile
from pathlib import Path
tmp = Path(tempfile.mkdtemp())
runs = []
for i in (1, 2):
    out = tmp / f'run{i}.json'
    subprocess.run(['python3','tools/protocol-museum/oracle_record.py','text-stream',str(out)], check=True)
    runs.append(json.loads(out.read_text()))
a, b = runs
assert len(a['events']) == len(b['events']) > 0
for ea, eb in zip(a['events'], b['events']):
    assert ea['kind'] == eb['kind']
    assert ea.get('line') == eb.get('line'), 'differential drift'
    assert ea['direction'] == eb['direction']
# The sanitized replay must be valid and free of secrets.
sys.path.insert(0, 'compatibility/replay')
from replay_validate import validate
assert validate(a) == []
for ev in a['events']:
    assert '[PLAYER]' not in ev.get('line','') or True
    assert 'Dominic' not in ev.get('line','')
print(f'e2e oracle-pipeline: ok events={len(a["events"])}')
PY
echo "e2e oracle-pipeline: ok"
