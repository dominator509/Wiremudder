#!/usr/bin/env sh
# LF-003 compatibility-oracle-roundtrip (live-fire)
#
# Proves the real user outcome of EP-003: a session captured from a live
# Protocol Museum fake MUD server round-trips through sanitize ->
# validate -> differential compare, producing a deterministic,
# schema-valid, secret-free replay that can drive compatibility checks
# independently of implementation tests.
set -eu
fail() { echo "LF-003: FAIL - $1" >&2; exit 1; }

echo "LF-003: compatibility-oracle-roundtrip"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

python3 - <<'PY' || fail "roundtrip"
import json, subprocess, sys, tempfile
from pathlib import Path
sys.path.insert(0, 'compatibility/replay')
from replay_validate import validate
sys.path.insert(0, 'compatibility/protocol-museum')
from museum import available_scenarios
scenarios = available_scenarios()
assert len(scenarios) >= 5, f'scenarios: {scenarios}'
tmp = Path(tempfile.mkdtemp())
total = 0
for sc in scenarios:
    out = tmp / f'{sc}.json'
    r = subprocess.run(['python3', 'tools/protocol-museum/oracle_record.py', sc, str(out)],
                       capture_output=True, text=True, timeout=20)
    assert r.returncode == 0, f'{sc}: {r.stderr}'
    doc = json.loads(out.read_text(encoding='utf-8'))
    errs = validate(doc)
    assert not errs, f'{sc} invalid: {errs}'
    sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    assert doc['client_version']['git_sha'] == sha, f'{sc} git_sha'
    total += len(doc['events'])
    print(f'  {sc}: {len(doc["events"])} events, schema ok, sanitized ok')
# Differential determinism across two runs of the richest scenario.
a = tmp / 'a.json'; b = tmp / 'b.json'
subprocess.run(['python3', 'tools/protocol-museum/oracle_record.py', 'text-stream', str(a)], check=True, timeout=20)
subprocess.run(['python3', 'tools/protocol-museum/oracle_record.py', 'text-stream', str(b)], check=True, timeout=20)
la = [e.get('line') for e in json.loads(a.read_text())['events']]
lb = [e.get('line') for e in json.loads(b.read_text())['events']]
assert la and la == lb, 'differential drift'
print(f'  differential: {len(la)} identical lines')
print(f'LF-003: ok scenarios={len(scenarios)} total_events={total}')
PY
