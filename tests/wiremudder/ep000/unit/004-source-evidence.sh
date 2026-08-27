#!/usr/bin/env sh
# Unit test: every source-evidence record is valid JSON with a matching
# output file and hash; evidence IDs are unique.
set -eu
python3 - <<'PY' || { echo "FAIL: source-evidence.jsonl invalid" >&2; exit 1; }
import hashlib, json
from pathlib import Path
ledger = Path('.agent/state/source-evidence.jsonl')
assert ledger.is_file(), 'missing source-evidence.jsonl'
ids = set()
n = 0
for raw in ledger.read_text(encoding='utf-8').splitlines():
    if not raw.strip():
        continue
    r = json.loads(raw)
    n += 1
    for field in ('schema_version','evidence_id','observed_at','repository','commit','path','symbol_or_range','claim','command','exit_code','output_path','output_sha256','agent_id'):
        assert field in r, f'missing field {field}'
    assert r['evidence_id'] not in ids, f'duplicate evidence id {r["evidence_id"]}'
    ids.add(r['evidence_id'])
    outp = Path(r['output_path'])
    assert outp.is_file(), f'missing output {r["output_path"]}'
    assert hashlib.sha256(outp.read_bytes()).hexdigest() == r['output_sha256'], f'hash drift {r["evidence_id"]}'
    assert r['exit_code'] == 0, f'non-zero exit {r["evidence_id"]}'
assert n >= 18, f'expected >= 18 evidence records, got {n}'
print(f'unit source-evidence: ok records={n}')
PY
echo "unit source-evidence: ok"
