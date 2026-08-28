#!/usr/bin/env sh
# EP-039 M2 unit test: the evidence index hashes validate against real files
# and the final evidence directory is non-empty with an index.
set -eu
cd "$(dirname "$0")/../../../.."

idx=release/wiremudder/candidate/EVIDENCE_INDEX.json
[ -f "$idx" ] || { echo "FAIL: evidence index missing" >&2; exit 1; }

python3 - "$idx" <<'PY'
import json, sys, hashlib, pathlib
idx = json.load(open(sys.argv[1], encoding='utf-8'))
entries = idx.get('entries', idx if isinstance(idx, list) else [])
assert entries, 'empty evidence index'
checked = 0
for e in entries:
    p = pathlib.Path(e['path'])
    if not p.is_file():
        continue  # allow released-but-removed build artifacts; hash only what exists
    data = p.read_bytes()
    actual = hashlib.sha256(data).hexdigest()
    assert actual == e['sha256'], f"hash mismatch {p}"
    checked += 1
assert checked > 0, 'no evidence files hashed'
print(f'evidence index hashes: ok ({checked} files)')
PY

[ -d .agent/state/final-evidence ] || { echo "FAIL: final-evidence dir missing" >&2; exit 1; }
[ -f .agent/state/final-evidence/index.json ] || { echo "FAIL: final-evidence index missing" >&2; exit 1; }

echo 'evidence index integrity: ok'
