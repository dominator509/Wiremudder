#!/usr/bin/env sh
# Unit test: COMMANDS.lock.tsv rows must reference evidence whose output
# contains the locked command, and the evidence output hash must match.
set -eu
[ -f .agent/state/COMMANDS.lock.tsv ] || { echo "FAIL: COMMANDS.lock.tsv missing" >&2; exit 1; }
python3 - <<'PY' || { echo "FAIL: COMMANDS.lock.tsv integrity" >&2; exit 1; }
import csv, hashlib, json
from pathlib import Path
rows = list(csv.DictReader(open('.agent/state/COMMANDS.lock.tsv', encoding='utf-8'), delimiter='\t'))
assert rows, 'empty command lock'
ev = {}
if Path('.agent/state/source-evidence.jsonl').is_file():
    for raw in Path('.agent/state/source-evidence.jsonl').read_text(encoding='utf-8').splitlines():
        if raw.strip():
            r = json.loads(raw); ev[r['evidence_id']] = r
for row in rows:
    assert row['key'] and row['command'] and row['evidence_id'] and row['owner_node'], row
    e = ev.get(row['evidence_id'])
    assert e, f"missing evidence {row['evidence_id']}"
    outp = Path(e['output_path'])
    assert outp.is_file(), f"missing evidence output {e['output_path']}"
    assert hashlib.sha256(outp.read_bytes()).hexdigest() == e['output_sha256'], f"hash drift {row['evidence_id']}"
    assert row['command'] in outp.read_text(encoding='utf-8', errors='replace'), f"command not in evidence {row['evidence_id']}"
print(f'unit command-lock: ok rows={len(rows)}')
PY
echo "unit command-lock: ok"
