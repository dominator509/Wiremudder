#!/usr/bin/env sh
# Unit test: upstream-tree inventory remained unchanged by EP-001 M1
# (no inherited file drift since the EP-000 baseline).
set -eu
python3 tests/wiremudder/ep000/unit/gen_upstream_tree.py >/dev/null
python3 - <<'PY' || { echo "FAIL: inventory drift" >&2; exit 1; }
import subprocess
from pathlib import Path
commit = '77086c295f4adf59197e586e689d19bdde8e1008'
ls = subprocess.run(['git','ls-tree','-r',commit], text=True, stdout=subprocess.PIPE).stdout
tree = {}
for line in ls.splitlines():
    meta, path = line.split('\t',1)
    parts = meta.split()
    if len(parts) == 3:
        tree[path] = parts[0]
inv = {}
for line in Path('.agent/state/upstream-tree.tsv').read_text(encoding='utf-8').splitlines()[1:]:
    if line.strip():
        parts = line.split('\t')
        inv[parts[0]] = parts[1]
assert set(tree) == set(inv), 'path set drift'
for p, mode in tree.items():
    expected = {'040000': 'tree', '160000': 'commit'}.get(mode, 'blob')
    assert inv.get(p) == expected, f'mismatch {p} ({mode} vs {inv.get(p)})'
print(f'unit upstream-inventory-stable: ok paths={len(tree)}')
PY
echo "unit upstream-inventory-stable: ok"
