#!/usr/bin/env python3
from __future__ import annotations
import re
import sys
from pathlib import Path
root = Path(__file__).resolve().parents[1]
text = (root / '.agent/GRAPH.md').read_text(encoding='utf-8')
inside = False
order = []
deps = {}
for line in text.splitlines():
    if line == 'GRAPH-TABLE-BEGIN': inside = True; continue
    if line == 'GRAPH-TABLE-END': inside = False; continue
    if inside and line.startswith('NODE '):
        parts = line.split()
        if len(parts) != 4 or parts[2] != 'DEPS':
            print(f'graph validation: FAIL - invalid line {line}', file=sys.stderr); raise SystemExit(1)
        order.append(parts[1]); deps[parts[1]] = [] if parts[3] == '-' else parts[3].split(',')
for node, ds in deps.items():
    for dep in ds:
        if dep not in deps or order.index(dep) >= order.index(node):
            print(f'graph validation: FAIL - invalid dependency {node}->{dep}', file=sys.stderr); raise SystemExit(1)
seen = set(); active = set()
def visit(n):
    if n in active:
        print(f'graph validation: FAIL - cycle at {n}', file=sys.stderr); raise SystemExit(1)
    if n in seen: return
    active.add(n)
    for d in deps[n]: visit(d)
    active.remove(n); seen.add(n)
for n in order: visit(n)
expected = {p.name[:6] for p in (root / '.agent/execplans').glob('EP-*.md')}
if set(order) != expected:
    print('graph validation: FAIL - graph and ExecPlans differ', file=sys.stderr); raise SystemExit(1)
print('graph validation: ok')
