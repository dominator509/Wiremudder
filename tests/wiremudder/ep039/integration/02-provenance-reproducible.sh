#!/usr/bin/env sh
# EP-039 M3 integration: the candidate evidence index hashes validate against
# real files AND the final release manifest reproduces from the recorded
# source commit (provenance integrity end to end).
set -eu
cd "$(dirname "$0")/../../../.."

python3 - <<'PY'
import hashlib, json, pathlib, subprocess
cand = pathlib.Path('release/wiremudder/candidate')
idx = json.loads((cand/'EVIDENCE_INDEX.json').read_text())
entries = idx.get('entries', idx if isinstance(idx, list) else [])
checked = 0
for e in entries:
    p = pathlib.Path(e['path'])
    if not p.is_file(): continue
    assert hashlib.sha256(p.read_bytes()).hexdigest() == e['sha256'], f"hash mismatch {p}"
    checked += 1
assert checked > 0
print(f'candidate evidence index: {checked} files ok')

fin = pathlib.Path('release/wiremudder/final')
m = json.loads((fin/'manifest.json').read_text())
src_commit = m['source_commit']
subprocess.run(['git','rev-parse','-q','--verify',f'{src_commit}^{{commit}}'], check=True, stdout=subprocess.DEVNULL)
archive = subprocess.run(['git','archive','--format=tar.gz',src_commit], check=True, stdout=subprocess.PIPE).stdout
actual = hashlib.sha256(archive).hexdigest()
recorded = next(a['sha256'] for a in m['artifacts'] if a['name']=='source.tar.gz')
assert actual == recorded, f"source archive not reproducible: {actual} != {recorded}"
print('final source archive reproducible from recorded commit')
PY
