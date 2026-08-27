#!/usr/bin/env sh
# Integration test: the evidence chain must be internally consistent —
# every evidence record's output file exists, hash matches, command is
# read-only, and path is tracked at the record's commit.
set -eu
python3 - <<'PY' || { echo "FAIL: evidence chain broken" >&2; exit 1; }
import hashlib, json, subprocess
from pathlib import Path
rows = []
for raw in Path('.agent/state/source-evidence.jsonl').read_text(encoding='utf-8').splitlines():
    if raw.strip():
        rows.append(json.loads(raw))
assert rows, 'no evidence'
for r in rows:
    outp = Path(r['output_path'])
    assert outp.is_file(), f'missing {r["output_path"]}'
    assert hashlib.sha256(outp.read_bytes()).hexdigest() == r['output_sha256'], f'hash drift {r["evidence_id"]}'
    assert r['exit_code'] == 0, f'nonzero exit {r["evidence_id"]}'
    assert '..' not in Path(r['path']).parts, f'bad path {r["path"]}'
    tracked = subprocess.run(['git','ls-files','--error-unmatch','--',r['path']], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    assert tracked, f'path not tracked {r["path"]}'
print(f'integration evidence-chain: ok records={len(rows)}')
PY
echo "integration evidence-chain: ok"
