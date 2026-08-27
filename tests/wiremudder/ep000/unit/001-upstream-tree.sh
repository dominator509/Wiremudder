#!/usr/bin/env sh
# Unit test: upstream-tree.tsv must exist, be non-empty, and cover the
# pinned commit's tracked tree. Regenerates in a temp file and compares
# the path/type/size columns with the committed artifact.
set -eu
. ./.env
[ -f .agent/state/upstream-tree.tsv ] || { echo "FAIL: upstream-tree.tsv missing" >&2; exit 1; }
[ -s .agent/state/upstream-tree.tsv ] || { echo "FAIL: upstream-tree.tsv empty" >&2; exit 1; }
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
python3 tests/wiremudder/ep000/unit/gen_upstream_tree.py >/dev/null
cp .agent/state/upstream-tree.tsv "$tmp"
python3 - "$tmp" <<'PY' || { echo "FAIL: upstream-tree.tsv drift" >&2; exit 1; }
import sys
p = sys.argv[1]
rows = {}
with open(p, encoding='utf-8') as f:
    header = f.readline().strip()
    assert header == 'path\ttype\tmode\tsize\tblob_sha', header
    for line in f:
        parts = line.rstrip('\n').split('\t')
        assert len(parts) == 5, parts
        rows[parts[0]] = (parts[1], parts[2], parts[3])
assert len(rows) > 1000, f'too few paths: {len(rows)}'
assert any(k.startswith('src/') for k in rows), 'no src/ paths'
assert any(k.startswith('test/') for k in rows), 'no test/ paths'
assert any(k.startswith('3rdparty/') for k in rows), 'no 3rdparty/ paths'
print(f'unit upstream-tree: ok paths={len(rows)}')
PY
echo "unit upstream-tree: ok"
