#!/usr/bin/env python3
from __future__ import annotations
import csv, sys
from pathlib import Path
root = Path.cwd()
with (root / '.agent/features/FEATURES.tsv').open(encoding='utf-8', newline='') as f:
    rows = list(csv.DictReader(f, delimiter='\t'))
if not rows:
    print('feature coverage: FAIL - empty', file=sys.stderr); raise SystemExit(1)
specs = {p.name[:8] for p in (root / '.agent/specs').glob('SPEC-*.md')}
nodes = {p.name[:6] for p in (root / '.agent/execplans').glob('EP-*.md')}
with (root / '.agent/live-fire/PROOFS.tsv').open(encoding='utf-8', newline='') as f:
    proofs = {r['id'] for r in csv.DictReader(f, delimiter='\t')}
seen = set()
for row in rows:
    required = ['id','status','profile','category','title','description','source','spec','node','test_path','proof']
    if any(not row.get(k,'').strip() for k in required):
        print(f'feature coverage: FAIL - incomplete {row}', file=sys.stderr); raise SystemExit(1)
    if row['id'] in seen:
        print(f'feature coverage: FAIL - duplicate {row["id"]}', file=sys.stderr); raise SystemExit(1)
    seen.add(row['id'])
    if row['spec'] not in specs or row['node'] not in nodes or row['proof'] not in proofs:
        print(f'feature coverage: FAIL - invalid trace {row["id"]}', file=sys.stderr); raise SystemExit(1)
    contract = root / f'.agent/node-contracts/{row["node"]}.md'
    if row['id'] not in contract.read_text(encoding='utf-8'):
        print(f'feature coverage: FAIL - missing from contract {row["id"]}', file=sys.stderr); raise SystemExit(1)
source_path = root / 'docs/provenance/SOURCE_FEATURE_COVERAGE.tsv'
if not source_path.is_file():
    print('feature coverage: FAIL - missing source feature coverage', file=sys.stderr); raise SystemExit(1)
with source_path.open(encoding='utf-8', newline='') as f:
    source_rows = list(csv.DictReader(f, delimiter='\t'))
if not source_rows:
    print('feature coverage: FAIL - empty source feature coverage', file=sys.stderr); raise SystemExit(1)
for row in source_rows:
    if any(not row.get(k,'').strip() for k in ['source','source_index','section','title','normalized_title','feature_id','spec','node']):
        print(f'feature coverage: FAIL - incomplete source feature row {row}', file=sys.stderr); raise SystemExit(1)
    if row['feature_id'] not in seen:
        print(f'feature coverage: FAIL - source feature missing authority row {row}', file=sys.stderr); raise SystemExit(1)
print(f'feature coverage: ok features={len(rows)} source_features={len(source_rows)}')
