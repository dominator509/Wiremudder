#!/usr/bin/env sh
# Integration test: the oracle harness records real TCP sessions against
# every museum scenario and produces valid, deterministic sanitized
# replays (SPEC-019-R04/R07/R08).
set -eu
python3 - <<'PY' || { echo "FAIL: museum integration" >&2; exit 1; }
import json, subprocess, sys, tempfile
from pathlib import Path
sys.path.insert(0, 'compatibility/replay')
from replay_validate import validate
sys.path.insert(0, 'compatibility/protocol-museum')
from museum import available_scenarios
scenarios = available_scenarios()
assert len(scenarios) >= 5, f'expected >=5 scenarios, got {scenarios}'
tmp = Path(tempfile.mkdtemp())
for sc in scenarios:
    out = tmp / f'{sc}.json'
    r = subprocess.run(['python3','tools/protocol-museum/oracle_record.py', sc, str(out)])
    assert r.returncode == 0, f'{sc} failed'
    doc = json.loads(out.read_text())
    assert validate(doc) == [], f'{sc} invalid'
    assert doc['client_version']['git_sha'] == subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip(), f'{sc} sha'
    for ev in doc['events']:
        text = ev.get('line', '')
        for bad in ('api_key','password=','AKIA'):
            assert bad not in text, f'{sc} leak: {bad}'
print(f'integration museum-all-scenarios: ok scenarios={len(scenarios)}')
PY
echo "integration museum-all-scenarios: ok"
