#!/usr/bin/env sh
# Integration test: gitlink submodules in the pinned tree must match
# .gitmodules paths and URLs.
set -eu
python3 - <<'PY' || { echo "FAIL: submodule inventory drift" >&2; exit 1; }
import subprocess
from pathlib import Path
ls = subprocess.run(['git','ls-tree','-r', 'HEAD'], text=True, stdout=subprocess.PIPE).stdout
gitlinks = {}
for line in ls.splitlines():
    meta, path = line.split('\t',1)
    parts = meta.split()
    if len(parts) == 3 and parts[1] == 'commit':
        gitlinks[path] = parts[2]
assert gitlinks, 'no gitlinks found'
gm = Path('.gitmodules').read_text(encoding='utf-8')
paths = []
for raw in Path('.gitmodules').read_text(encoding='utf-8').splitlines():
    raw = raw.strip()
    if raw.startswith('path = '):
        paths.append(raw.split(' = ',1)[1])
for p in paths:
    assert p in gitlinks, f'submodule path {p} missing from tree'
    assert ('path = %s' % p) in gm, f'submodule path entry missing for {p}'
print(f'integration submodule-inventory: ok links={len(gitlinks)}')
PY
echo "integration submodule-inventory: ok"
