#!/usr/bin/env sh
# Unit test: oracle recorder produces a schema-valid sanitized replay
# for every museum scenario over a real TCP session.
set -eu
python3 - <<'PY' || { echo "FAIL: oracle record" >&2; exit 1; }
import json, subprocess, sys, tempfile
from pathlib import Path
sys.path.insert(0, 'compatibility/replay')
from replay_validate import validate
for scenario in ('negotiation', 'text-stream', 'latency', 'disconnect'):
    out = Path(tempfile.mkdtemp()) / f'{scenario}.json'
    rc = subprocess.run(['python3', 'tools/protocol-museum/oracle_record.py', scenario, str(out)])
    assert rc.returncode == 0, f'capture failed for {scenario}'
    doc = json.loads(out.read_text(encoding='utf-8'))
    assert validate(doc) == [], f'validation failed for {scenario}: {validate(doc)}'
    assert doc['events'], f'no events for {scenario}'
    for ev in doc['events']:
        assert 'api_key' not in ev.get('line', '').lower()
print('unit oracle-record: ok')
PY
echo "unit oracle-record: ok"
