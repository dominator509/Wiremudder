#!/usr/bin/env python3
from pathlib import Path
import re, sys
node = sys.argv[1]; base = ''
for line in Path('.agent/state/LEDGER.md').read_text(encoding='utf-8').splitlines():
    p = line.split(' | ', 4)
    if len(p) == 5 and p[2] == node and p[3] in {'LEASE', 'LEASE_TAKEOVER'}:
        m = re.search(r'\bbase=([0-9a-f]{40})\b', p[4])
        if m: base = m.group(1)
if not base:
    print('lease base: missing', file=sys.stderr); raise SystemExit(1)
print(base)
