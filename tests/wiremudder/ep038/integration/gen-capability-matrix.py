#!/usr/bin/env python3
"""Generate docs/wiremudder/release-candidate/CAPABILITY_MATRIX.tsv from
real repository evidence (EP-038 M3). One row per feature in FEATURES.tsv.
States are honest: a feature is live-fire-certified only when its owning
node is green and its M5 evidence exists; research features are blocked;
EP-038's own feature is tested until LF-038 certifies it at M5.
"""
from __future__ import annotations
import csv
from pathlib import Path

root = Path.cwd()
features = list(csv.DictReader((root / '.agent/features/FEATURES.tsv').open(encoding='utf-8', newline=''), delimiter='\t'))

def green(node: str) -> bool:
    import subprocess
    return subprocess.run(['git', 'rev-parse', '-q', '--verify', f'refs/tags/green/{node}'],
                          stdout=subprocess.DEVNULL).returncode == 0

rows = []
for f in features:
    fid, profile, node = f['id'], f['profile'], f['node']
    ev = f'.agent/state/evidence/{node}/M5/evidence.json'
    if profile == 'future':                      # research-decision-required
        state, evidence = 'blocked', ''
    elif node == 'EP-038':                        # own feature: certified at M5
        state, evidence = 'tested', 'tests/wiremudder/ep038/unit/'
    elif green(node) and (root / ev).is_file():   # node green with M5 evidence
        state, evidence = 'live-fire-certified', ev
    else:
        state, evidence = 'declared', ''
    rows.append((fid, state, evidence))

out = root / 'docs/wiremudder/release-candidate/CAPABILITY_MATRIX.tsv'
with out.open('w', encoding='utf-8', newline='') as h:
    h.write('feature_id\tstate\tevidence\n')
    for fid, state, evidence in rows:
        h.write(f'{fid}\t{state}\t{evidence}\n')
print(f'capability matrix: {len(rows)} rows -> {out}')
