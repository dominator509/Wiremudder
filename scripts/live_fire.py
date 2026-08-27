#!/usr/bin/env python3
from __future__ import annotations
import csv, subprocess, sys
from pathlib import Path
root = Path.cwd()
with (root / '.agent/live-fire/PROOFS.tsv').open(encoding='utf-8', newline='') as f:
    rows = list(csv.DictReader(f, delimiter='\t'))
ran = 0
for row in rows:
    if row['node'] == 'EP-039':
        continue
    status = subprocess.check_output(['sh','scripts/ledger.sh','status',row['node']], text=True).strip()
    if status != 'DONE':
        continue
    script = root / row['script']
    if not script.is_file():
        print(f'live-fire: FAIL - missing {row["script"]}', file=sys.stderr); raise SystemExit(1)
    expected = f'{row["id"]} {row["name"]}: ok'
    proc = subprocess.run(['sh', str(script)], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(proc.stdout, end='')
    if proc.returncode != 0 or expected not in proc.stdout:
        print(f'live-fire: FAIL - {row["id"]}', file=sys.stderr); raise SystemExit(1)
    ran += 1
if ran == 0:
    print('live-fire: FAIL - no completed-node proofs available', file=sys.stderr); raise SystemExit(1)
print('live-fire: ok')
