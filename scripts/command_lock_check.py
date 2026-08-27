#!/usr/bin/env python3
from __future__ import annotations
import csv, hashlib, json, re, subprocess, sys
from pathlib import Path
path = Path('.agent/state/COMMANDS.lock.tsv')
if not path.is_file():
    print('command lock check: FAIL - missing file', file=sys.stderr); raise SystemExit(1)
check = subprocess.run(['python3','scripts/source_evidence_check.py'], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
if check.returncode != 0:
    print(check.stdout, end='', file=sys.stderr)
    print('command lock check: FAIL - source evidence integrity', file=sys.stderr); raise SystemExit(check.returncode)
expected = ['key','command','evidence_id','owner_node','platform','verified_at']
with path.open(encoding='utf-8', newline='') as handle:
    reader = csv.DictReader(handle, delimiter='\t'); rows = list(reader); header = reader.fieldnames or []
if header != expected:
    print('command lock check: FAIL - invalid header', file=sys.stderr); raise SystemExit(1)
allowed_keys = {'install','configure','build','unit','integration','e2e','lint','typecheck','smoke','static-analysis','package','start','stop','security','dependency_audit','compatibility','performance','accessibility','platform','license'}
allowed_platforms = {'all','linux','macos','windows'}
dangerous = ('rm -rf','git reset --hard','git push --force','git clean -fdx','git clean -ffdx')
evidence_rows = {}; evidence_file = Path('.agent/state/source-evidence.jsonl')
for raw in evidence_file.read_text(encoding='utf-8').splitlines():
    if raw.strip():
        row = json.loads(raw); evidence_rows[str(row.get('evidence_id',''))] = row
seen = set()
for row in rows:
    key = str(row.get('key','')); platform = str(row.get('platform','')).lower(); command = str(row.get('command','')); evidence_id = str(row.get('evidence_id',''))
    pair = (key, platform)
    if pair in seen or key not in allowed_keys or platform not in allowed_platforms or not command or len(command) > 2000 or not re.fullmatch(r'EP-\d{3}', row.get('owner_node','')) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', row.get('verified_at','')):
        print(f'command lock check: FAIL - invalid row {pair}', file=sys.stderr); raise SystemExit(1)
    if '\n' in command or '\r' in command or '\t' in command or any(token in command for token in dangerous):
        print(f'command lock check: FAIL - unsafe command {pair}', file=sys.stderr); raise SystemExit(1)
    seen.add(pair)
    ev = evidence_rows.get(evidence_id)
    if not ev:
        print(f'command lock check: FAIL - unknown evidence {evidence_id}', file=sys.stderr); raise SystemExit(1)
    source_path = str(ev.get('path',''))
    allowed_source = source_path in {'docs/ai-instructions.md','CMakePresets.json','CMakeLists.txt'} or source_path.startswith('.agents/skills/') or source_path.startswith('CI/') or source_path.startswith('.github/workflows/')
    if not allowed_source:
        print(f'command lock check: FAIL - untrusted command source {source_path}', file=sys.stderr); raise SystemExit(1)
    output_path = Path(str(ev.get('output_path','')))
    if not output_path.is_file() or hashlib.sha256(output_path.read_bytes()).hexdigest() != ev.get('output_sha256'):
        print(f'command lock check: FAIL - evidence output integrity {evidence_id}', file=sys.stderr); raise SystemExit(1)
    if command not in output_path.read_text(encoding='utf-8', errors='replace'):
        print(f'command lock check: FAIL - exact command absent from evidence {pair}', file=sys.stderr); raise SystemExit(1)
    commit = str(ev.get('commit',''))
    if subprocess.run(['git','merge-base','--is-ancestor',commit,'HEAD'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
        print(f'command lock check: FAIL - stale evidence {evidence_id}', file=sys.stderr); raise SystemExit(1)
print(f'command lock check: ok rows={len(rows)}')
