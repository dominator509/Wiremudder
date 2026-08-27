#!/usr/bin/env python3
from __future__ import annotations
import json, re, subprocess, sys
from pathlib import Path
root = Path.cwd(); node = sys.argv[1] if len(sys.argv) > 1 else ''
if not re.fullmatch(r'EP-\d{3}', node):
    print('expected files audit: invalid node', file=sys.stderr); raise SystemExit(2)
static_file = root / f'.agent/expected-files/{node}.txt'
if not static_file.is_file():
    print(f'expected files audit {node}: FAIL - missing static fence', file=sys.stderr); raise SystemExit(1)
expected = [line.strip() for line in static_file.read_text(encoding='utf-8').splitlines() if line.strip() and not line.lstrip().startswith('#')]
disc = root / f'.agent/expected-files/{node}.discovered.txt'
if disc.is_file():
    for raw in disc.read_text(encoding='utf-8').splitlines():
        if raw.strip() and not raw.lstrip().startswith('#'):
            expected.append(str(json.loads(raw)['path']))
missing = []
for item in expected:
    path = root / item
    if item.endswith('/'):
        if not path.is_dir() or not any(p.is_file() for p in path.rglob('*')): missing.append(item)
    elif not path.exists(): missing.append(item)
if missing:
    print(f'expected files audit {node}: FAIL - missing or empty required outputs', file=sys.stderr)
    for item in missing: print(item, file=sys.stderr)
    raise SystemExit(1)
proc = subprocess.run(['sh','scripts/scope-audit.sh',node])
if proc.returncode != 0: raise SystemExit(proc.returncode)
print(f'expected files audit {node}: ok paths={len(expected)}')
