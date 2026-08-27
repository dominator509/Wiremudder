#!/usr/bin/env python3
from __future__ import annotations
import csv, sys
from pathlib import Path
root = Path.cwd()
with (root / 'docs/provenance/SOURCE_DOCUMENT_COVERAGE.tsv').open(encoding='utf-8', newline='') as f:
    rows = list(csv.DictReader(f, delimiter='\t'))
seen = set()
first_generation = 0
for row in rows:
    if any(not row.get(k,'').strip() for k in ['source','sha256','disposition','authoritative_destination']):
        print(f'source coverage: FAIL - incomplete {row}', file=sys.stderr); raise SystemExit(1)
    if row['source'] in seen:
        print(f'source coverage: FAIL - duplicate {row["source"]}', file=sys.stderr); raise SystemExit(1)
    seen.add(row['source'])
    if row['source'].startswith('first-generation-pack/'):
        first_generation += 1
if first_generation != 71:
    print(f'source coverage: FAIL - expected 71 first-generation files, got {first_generation}', file=sys.stderr); raise SystemExit(1)
with (root / 'docs/provenance/LEGACY_REQUIREMENT_INVENTORY.tsv').open(encoding='utf-8', newline='') as f:
    inv = list(csv.DictReader(f, delimiter='\t'))
if not inv or any(not r.get('destination','').strip() or not r.get('disposition','').strip() for r in inv):
    print('source coverage: FAIL - requirement inventory incomplete', file=sys.stderr); raise SystemExit(1)
print('source coverage: ok')
