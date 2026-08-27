#!/usr/bin/env python3
from __future__ import annotations
import csv, re, sys
from pathlib import Path
root = Path.cwd()
with (root / '.agent/requirements/VALIDATION_MATRIX.tsv').open(encoding='utf-8', newline='') as f:
    rows = list(csv.DictReader(f, delimiter='\t'))
seen = set()
for row in rows:
    req = row.get('requirement_id','')
    if not req or req in seen:
        print(f'spec trace: FAIL - invalid or duplicate {req}', file=sys.stderr); raise SystemExit(1)
    seen.add(req)
    spec = root / row['spec_file']
    if not spec.is_file() or req not in spec.read_text(encoding='utf-8'):
        print(f'spec trace: FAIL - requirement absent from spec {req}', file=sys.stderr); raise SystemExit(1)
    contract = root / f'.agent/node-contracts/{row["node_id"]}.md'
    if not contract.is_file() or req not in contract.read_text(encoding='utf-8'):
        print(f'spec trace: FAIL - requirement absent from node contract {req}', file=sys.stderr); raise SystemExit(1)
    if not row.get('test_path') or not row.get('proof_id') or not row.get('verification_class'):
        print(f'spec trace: FAIL - incomplete route {req}', file=sys.stderr); raise SystemExit(1)
for spec in (root / '.agent/specs').glob('SPEC-*.md'):
    ids = set(re.findall(r'WM-SPEC-\d{3}-R\d{2}', spec.read_text(encoding='utf-8')))
    missing = ids - seen
    if missing:
        print(f'spec trace: FAIL - unmapped {sorted(missing)}', file=sys.stderr); raise SystemExit(1)
print('spec trace: ok')
