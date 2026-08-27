#!/usr/bin/env python3
from __future__ import annotations
import csv, hashlib, sys
from pathlib import Path

ROOT = Path.cwd(); ledger = ROOT / '.agent/AUTHORITY_FILES.tsv'
if not ledger.is_file():
    print('authority check: FAIL - missing authority ledger', file=sys.stderr); raise SystemExit(1)
with ledger.open(encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
with ledger.open(encoding='utf-8', newline='') as handle:
    header = next(csv.reader(handle, delimiter='\t'), [])
if header != ['path','mode','sha256'] or not rows:
    print('authority check: FAIL - invalid authority ledger', file=sys.stderr); raise SystemExit(1)

def digest(path: Path, mode: str) -> str:
    data = path.read_bytes()
    if mode == 'prefix-before-progress':
        marker = b'\n# 11. Progress\n'
        if marker not in data:
            print(f'authority check: FAIL - ExecPlan progress marker missing: {path}', file=sys.stderr); raise SystemExit(1)
        data = data.split(marker, 1)[0] + marker
    elif mode != 'full':
        print(f'authority check: FAIL - unknown mode {mode}', file=sys.stderr); raise SystemExit(1)
    return hashlib.sha256(data).hexdigest()

listed = set()
for row in rows:
    rel = row['path']; listed.add(rel); path = ROOT / rel
    if not path.is_file():
        print(f'authority check: FAIL - missing {rel}', file=sys.stderr); raise SystemExit(1)
    if digest(path, row['mode']) != row['sha256']:
        print(f'authority check: FAIL - authority drift {rel}', file=sys.stderr); raise SystemExit(1)

def candidate(rel: str) -> bool:
    if rel in listed: return True
    if rel in {'.agent/AUTHORITY_FILES.tsv','.agent/MANIFEST.tsv','.agent/MANIFEST.md','PACK_SHA256SUMS.txt'}: return False
    if rel.startswith('.agent/state/'): return False
    if rel.startswith('.agent/expected-files/') and rel.endswith('.discovered.txt'): return False
    if rel.startswith('scripts/node-verifiers/') or rel.startswith('tests/live-fire/'): return False
    if rel.startswith('.agent/'): return True
    if rel in {'.github/copilot-instructions.md','.cursor/rules/wiremudder-graphlock.mdc','.clinerules/wiremudder-graphlock.md'}: return True
    return False
actual = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*') if p.is_file() and candidate(p.relative_to(ROOT).as_posix())}
extra = sorted(actual - listed); missing = sorted(listed - actual)
if extra or missing:
    print(f'authority check: FAIL - untracked={extra} missing={missing}', file=sys.stderr); raise SystemExit(1)
print(f'authority check: ok files={len(rows)}')
