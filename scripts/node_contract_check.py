#!/usr/bin/env python3
from __future__ import annotations
import csv, re, sys
from pathlib import Path
root = Path.cwd(); node = sys.argv[1] if len(sys.argv) > 1 else ''
if not re.fullmatch(r'EP-\d{3}', node):
    print('node contract check: invalid node', file=sys.stderr); raise SystemExit(2)
required = [
    root / f'.agent/node-contracts/{node}.md',
    root / f'.agent/expected-files/{node}.txt',
    root / f'.agent/expected-files/{node}.discovered.txt',
]
required += [root / f'.agent/milestone-files/{node}-M{i}.txt' for i in range(1,6)]
for p in required:
    if not p.is_file():
        print(f'node contract check {node}: FAIL - missing {p}', file=sys.stderr); raise SystemExit(1)
with (root / '.agent/features/FEATURES.tsv').open(encoding='utf-8', newline='') as f:
    features = [r for r in csv.DictReader(f, delimiter='\t') if r['node'] == node]
with (root / '.agent/requirements/VALIDATION_MATRIX.tsv').open(encoding='utf-8', newline='') as f:
    reqs = [r for r in csv.DictReader(f, delimiter='\t') if r['node_id'] == node]
contract = (root / f'.agent/node-contracts/{node}.md').read_text(encoding='utf-8')
for row in features:
    if row['id'] not in contract:
        print(f'node contract check {node}: FAIL - feature missing {row["id"]}', file=sys.stderr); raise SystemExit(1)
for row in reqs:
    if row['requirement_id'] not in contract:
        print(f'node contract check {node}: FAIL - requirement missing {row["requirement_id"]}', file=sys.stderr); raise SystemExit(1)
print(f'node contract check {node}: ok')
