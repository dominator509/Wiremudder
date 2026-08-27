#!/usr/bin/env python3
from __future__ import annotations
import csv, sys
from pathlib import Path
root = Path.cwd(); manifest = root / '.agent/MANIFEST.tsv'
with manifest.open(encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
needle = chr(123) * 2
for row in rows:
    rel = row['path']
    if rel.startswith('.agent/state/'):
        continue
    if not (rel.startswith('.agent/') or rel.startswith('scripts/') or rel in {'AGENTS.md','COMMANDS.md','ARCHITECTURE.md','WIREMUDDER_SECURITY.md','TESTING.md'}):
        continue
    path = root / rel
    try: text = path.read_text(encoding='ascii')
    except (UnicodeDecodeError, OSError):
        print(f'placeholder check: FAIL - unreadable {rel}', file=sys.stderr); raise SystemExit(1)
    if needle in text:
        print(f'placeholder check: FAIL - unresolved double-brace token {rel}', file=sys.stderr); raise SystemExit(1)
print('placeholder check: ok')
