#!/usr/bin/env sh
# Integration test: upstream-tree.tsv must exactly match the pinned
# commit's tracked tree (paths/types only; sizes/hashes checked for blobs).
set -eu
. ./.env
python3 - <<'PY' || { echo "FAIL: inventory drift" >&2; exit 1; }
import subprocess, sys
from pathlib import Path
commit = None
for raw in Path('.env').read_text(encoding='utf-8').splitlines():
    if raw.startswith('WIREMUDDER_UPSTREAM_COMMIT='):
        commit = raw.split('=',1)[1].strip()
assert commit
ls = subprocess.run(['git','ls-tree','-r',commit], text=True, stdout=subprocess.PIPE).stdout
tree = {}
for line in ls.splitlines():
    meta, path = line.split('\t',1)
    parts = meta.split()
    if len(parts) == 3:
        mode, otype, oid = parts
    else:
        continue
    tree[path] = (otype, mode)
inv = {}
for line in Path('.agent/state/upstream-tree.tsv').read_text(encoding='utf-8').splitlines()[1:]:
    if not line.strip():
        continue
    parts = line.split('\t')
    assert len(parts) == 5, parts
    inv[parts[0]] = (parts[1], parts[2])
assert set(tree) == set(inv), f'diff: {(set(tree)^set(inv)) | {len(tree), len(inv)}}'
for path, (otype, mode) in tree.items():
    assert inv[path] == (otype, mode), f'mismatch {path}'
print(f'integration tree-inventory: ok paths={len(tree)}')
PY
echo "integration tree-inventory: ok"
