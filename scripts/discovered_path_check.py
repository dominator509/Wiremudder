#!/usr/bin/env python3
from __future__ import annotations
import json, re, subprocess, sys
from pathlib import Path

ROOT = Path.cwd(); node = sys.argv[1] if len(sys.argv) > 1 else ''
if not re.fullmatch(r'EP-\d{3}', node):
    print('discovered path check: invalid node', file=sys.stderr); raise SystemExit(2)
source_rows = {}
source = ROOT / '.agent/state/source-evidence.jsonl'
if source.is_file():
    for raw in source.read_text(encoding='utf-8').splitlines():
        if raw.strip():
            row = json.loads(raw); source_rows[row.get('evidence_id')] = row
path = ROOT / f'.agent/expected-files/{node}.discovered.txt'
required = {'node','source_evidence_id','repository_commit','path','rationale','test','rollback','added_at','agent_id'}
seen = set(); count = 0
if path.is_file():
    for lineno, raw in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
        if not raw.strip() or raw.lstrip().startswith('#'): continue
        try: row = json.loads(raw)
        except json.JSONDecodeError as exc:
            print(f'discovered path check {node}: FAIL - line {lineno}: {exc}', file=sys.stderr); raise SystemExit(1)
        if required - set(row) or row.get('node') != node:
            print(f'discovered path check {node}: FAIL - invalid fields line {lineno}', file=sys.stderr); raise SystemExit(1)
        p = str(row['path'])
        if p in seen or p.endswith('/') or Path(p).is_absolute() or '..' in Path(p).parts:
            print(f'discovered path check {node}: FAIL - invalid or duplicate path {p}', file=sys.stderr); raise SystemExit(1)
        seen.add(p); count += 1
        ev = source_rows.get(row['source_evidence_id'])
        if not ev or ev.get('path') != p or ev.get('commit') != row['repository_commit']:
            print(f'discovered path check {node}: FAIL - evidence mismatch for {p}', file=sys.stderr); raise SystemExit(1)
        if subprocess.run(['git','merge-base','--is-ancestor',str(row['repository_commit']),'HEAD']).returncode != 0:
            print(f'discovered path check {node}: FAIL - stale or foreign evidence for {p}', file=sys.stderr); raise SystemExit(1)
        if not (ROOT / p).is_file() or subprocess.run(['git','ls-files','--error-unmatch','--',p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
            print(f'discovered path check {node}: FAIL - inherited path not tracked {p}', file=sys.stderr); raise SystemExit(1)
        test = str(row['test'])
        if not (ROOT / test).is_file() or not (test.startswith('tests/wiremudder/') or test.startswith('compatibility/')):
            print(f'discovered path check {node}: FAIL - independent test missing {test}', file=sys.stderr); raise SystemExit(1)
        if len(str(row['rationale']).strip()) < 20 or len(str(row['rollback']).strip()) < 10:
            print(f'discovered path check {node}: FAIL - weak rationale or rollback for {p}', file=sys.stderr); raise SystemExit(1)
print(f'discovered path check {node}: ok rows={count}')
