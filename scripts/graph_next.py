#!/usr/bin/env python3
from __future__ import annotations
import re
import sys
from pathlib import Path
root = Path(__file__).resolve().parents[1]

def parse_graph():
    text = (root / '.agent/GRAPH.md').read_text(encoding='utf-8')
    inside = False; order = []; deps = {}
    for line in text.splitlines():
        if line == 'GRAPH-TABLE-BEGIN': inside = True; continue
        if line == 'GRAPH-TABLE-END': inside = False; continue
        if inside and line.startswith('NODE '):
            p = line.split(); order.append(p[1]); deps[p[1]] = [] if p[3] == '-' else p[3].split(',')
    return order, deps

def statuses(order):
    state = {n: 'PENDING' for n in order}
    ledger = root / '.agent/state/LEDGER.md'
    if not ledger.exists(): return state
    for line in ledger.read_text(encoding='utf-8').splitlines():
        parts = line.split(' | ', 4)
        if len(parts) != 5: continue
        _, _, node, event, _ = parts
        if node not in state: continue
        if event == 'NODE_DONE': state[node] = 'DONE'
        elif event == 'NODE_BLOCKED': state[node] = 'BLOCKED'
        elif event in {'LEASE', 'LEASE_TAKEOVER'}: state[node] = 'IN_PROGRESS'
        elif event == 'LEASE_RELEASE' and state[node] != 'DONE': state[node] = 'PENDING'
    return state
order, deps = parse_graph(); state = statuses(order)
for node in order:
    if state[node] == 'BLOCKED': print(f'BLOCKED {node}'); raise SystemExit(0)
for node in order:
    if state[node] == 'IN_PROGRESS': print(f'RESUME {node}'); raise SystemExit(0)
for node in order:
    if state[node] == 'PENDING' and all(state[d] == 'DONE' for d in deps[node]):
        print(f'NEXT {node}'); raise SystemExit(0)
undone = [n for n in order if state[n] != 'DONE']
print('ALL_DONE' if not undone else f'STALL {undone[0]}')
