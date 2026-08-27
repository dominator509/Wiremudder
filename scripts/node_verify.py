#!/usr/bin/env python3
from __future__ import annotations
import json, re, subprocess, sys
from pathlib import Path
node = sys.argv[1] if len(sys.argv) > 1 else ''
if not re.fullmatch(r'EP-\d{3}', node):
    print('node verify: invalid node', file=sys.stderr); raise SystemExit(2)
root = Path.cwd()
plan_matches = list((root / '.agent/execplans').glob(f'{node}-*.md'))
if len(plan_matches) != 1:
    print(f'node verify {node}: FAIL - ExecPlan count', file=sys.stderr); raise SystemExit(1)
text = plan_matches[0].read_text(encoding='utf-8')
for label in ['M1:', 'M2:', 'M3:', 'M4:', 'M5:']:
    if f'- [x] {label}' not in text:
        print(f'node verify {node}: FAIL - unchecked {label}', file=sys.stderr); raise SystemExit(1)
for i in range(1,6):
    path = root / f'.agent/state/evidence/{node}/M{i}/evidence.json'
    if not path.is_file():
        print(f'node verify {node}: FAIL - missing {path}', file=sys.stderr); raise SystemExit(1)
    data = json.loads(path.read_text(encoding='utf-8'))
    if data.get('exit_code') != 0 or not data.get('sentinel_observed'):
        print(f'node verify {node}: FAIL - invalid M{i} evidence', file=sys.stderr); raise SystemExit(1)
verifier = root / f'scripts/node-verifiers/{node}.sh'
if not verifier.is_file():
    print(f'node verify {node}: FAIL - missing node verifier', file=sys.stderr); raise SystemExit(1)
proc = subprocess.run(['sh', str(verifier), 'verify'], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
expected = f'{node} verify: ok'
print(proc.stdout, end='')
if proc.returncode != 0 or expected not in proc.stdout:
    print(f'node verify {node}: FAIL - verifier sentinel', file=sys.stderr); raise SystemExit(1)
for cmd in [
    ['sh','scripts/authority-check.sh'],
    ['sh','scripts/source-evidence-check.sh'],
    ['sh','scripts/discovered-path-check.sh',node],
    ['sh','scripts/node-contract-check.sh',node],
    ['sh','scripts/expected-files-audit.sh',node],
    ['sh','scripts/scope-audit.sh',node],
    ['sh','scripts/feature-coverage-check.sh'],
    ['sh','scripts/spec-trace-check.sh'],
]:
    p = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(p.stdout, end='')
    if p.returncode != 0: raise SystemExit(p.returncode)
print(f'node verify {node}: ok')
