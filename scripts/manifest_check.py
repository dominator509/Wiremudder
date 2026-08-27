#!/usr/bin/env python3
from __future__ import annotations
import csv, re, sys
from pathlib import Path
root = Path.cwd(); manifest = root / '.agent/MANIFEST.tsv'; manifest_md = root / '.agent/MANIFEST.md'
if not manifest.is_file() or not manifest_md.is_file():
    print('manifest check: FAIL - missing manifest', file=sys.stderr); raise SystemExit(1)
with manifest.open(encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
with manifest.open(encoding='utf-8', newline='') as handle:
    header = next(csv.reader(handle, delimiter='\t'), [])
if header != ['path','layer','purpose'] or not rows:
    print('manifest check: FAIL - invalid manifest schema', file=sys.stderr); raise SystemExit(1)
paths = [row.get('path','') for row in rows]
if len(paths) != len(set(paths)) or any(not p or Path(p).is_absolute() or '..' in Path(p).parts for p in paths):
    print('manifest check: FAIL - duplicate or unsafe path', file=sys.stderr); raise SystemExit(1)
for row in rows:
    if row.get('layer') not in {'L1','L2','L3','L4','L5','L6'} or not row.get('purpose','').strip():
        print(f'manifest check: FAIL - invalid row {row}', file=sys.stderr); raise SystemExit(1)
    if not (root / row['path']).is_file():
        print(f'manifest check: FAIL - missing {row["path"]}', file=sys.stderr); raise SystemExit(1)
match = re.search(r'^TOTAL FILES: (\d+)$', manifest_md.read_text(encoding='utf-8'), re.M)
if not match or int(match.group(1)) != len(rows):
    print('manifest check: FAIL - Markdown count mismatch', file=sys.stderr); raise SystemExit(1)
print(f'manifest check: ok files={len(rows)}')
