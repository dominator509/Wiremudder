#!/usr/bin/env python3
from __future__ import annotations
import json, re, subprocess, sys
from pathlib import Path
node = sys.argv[1] if len(sys.argv) > 1 else ''
if not re.fullmatch(r'EP-\d{3}', node):
    print('scope audit: invalid node', file=sys.stderr); raise SystemExit(2)
root = Path.cwd()

def static_paths(path: Path) -> list[str]:
    if not path.is_file(): return []
    return [line.strip() for line in path.read_text(encoding='utf-8').splitlines() if line.strip() and not line.lstrip().startswith('#')]

def discovered_paths(path: Path) -> list[str]:
    result = []
    if not path.is_file(): return result
    for raw in path.read_text(encoding='utf-8').splitlines():
        if raw.strip() and not raw.lstrip().startswith('#'):
            result.append(str(json.loads(raw)['path']))
    return result

check = subprocess.run(['python3','scripts/discovered_path_check.py',node])
if check.returncode != 0: raise SystemExit(check.returncode)
allowed = static_paths(root / f'.agent/expected-files/{node}.txt') + discovered_paths(root / f'.agent/expected-files/{node}.discovered.txt')
if not allowed:
    print(f'scope audit {node}: FAIL - no allowed paths', file=sys.stderr); raise SystemExit(1)
base = ''
for line in (root / '.agent/state/LEDGER.md').read_text(encoding='utf-8').splitlines():
    p = line.split(' | ', 4)
    if len(p) == 5 and p[2] == node and p[3] in {'LEASE', 'LEASE_TAKEOVER'}:
        m = re.search(r'\bbase=([0-9a-f]{40})\b', p[4])
        if m: base = m.group(1)
if not base:
    print(f'scope audit {node}: FAIL - no lease base in ledger', file=sys.stderr); raise SystemExit(1)
if subprocess.run(['git','cat-file','-e',base + '^{commit}'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
    print(f'scope audit {node}: FAIL - invalid lease base {base}', file=sys.stderr); raise SystemExit(1)
changed = set()
for args in (
    ['git','diff','--name-only',f'{base}..HEAD'],
    ['git','diff','--name-only'],
    ['git','diff','--name-only','--cached'],
):
    proc = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        print(f'scope audit {node}: FAIL - command failed: {" ".join(args)}', file=sys.stderr); raise SystemExit(1)
    changed.update(x for x in proc.stdout.splitlines() if x)
proc = subprocess.run(['git','ls-files','--others','--exclude-standard'], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
if proc.returncode != 0:
    print(f'scope audit {node}: FAIL - cannot list untracked files', file=sys.stderr); raise SystemExit(1)
changed.update(x for x in proc.stdout.splitlines() if x)

def permitted(path: str) -> bool:
    for item in allowed:
        if item.endswith('/') and path.startswith(item): return True
        if path == item: return True
    return False
bad = sorted(p for p in changed if not permitted(p))
if bad:
    print(f'scope audit {node}: FAIL - unauthorized paths', file=sys.stderr)
    for p in bad: print(p, file=sys.stderr)
    raise SystemExit(1)
print(f'scope audit {node}: ok changed={len(changed)}')
