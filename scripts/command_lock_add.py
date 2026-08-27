#!/usr/bin/env python3
from __future__ import annotations
import csv, hashlib, json, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

if len(sys.argv) < 6:
    print('usage: command_lock_add.py KEY EVIDENCE_ID OWNER_NODE PLATFORM COMMAND', file=sys.stderr); raise SystemExit(2)
key, evidence_id, owner_node, platform = sys.argv[1:5]
platform = platform.strip().lower()
command = ' '.join(sys.argv[5:]).strip()
allowed_keys = {'install','configure','build','unit','integration','e2e','lint','typecheck','smoke','static-analysis','package','start','stop','security','dependency_audit','compatibility','performance','accessibility','platform','license'}
allowed_platforms = {'all','linux','macos','windows'}
dangerous = ('rm -rf','git reset --hard','git push --force','git clean -fdx','git clean -ffdx')
if key not in allowed_keys or not re.fullmatch(r'EP-\d{3}', owner_node) or platform not in allowed_platforms or not command or len(command) > 2000:
    print('command lock add: invalid fields', file=sys.stderr); raise SystemExit(1)
if '\n' in command or '\r' in command or '\t' in command or any(token in command for token in dangerous):
    print('command lock add: destructive, multiline, or malformed command rejected', file=sys.stderr); raise SystemExit(1)
check = subprocess.run(['python3','scripts/source_evidence_check.py'], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
if check.returncode != 0:
    print(check.stdout, end='', file=sys.stderr)
    print('command lock add: source evidence integrity failed', file=sys.stderr); raise SystemExit(check.returncode)
evidence_file = Path('.agent/state/source-evidence.jsonl'); evidence_rows = {}
if evidence_file.is_file():
    for raw in evidence_file.read_text(encoding='utf-8').splitlines():
        if raw.strip():
            row = json.loads(raw); evidence_rows[str(row.get('evidence_id',''))] = row
evidence_row = evidence_rows.get(evidence_id)
if not evidence_row:
    print(f'command lock add: unknown evidence ID {evidence_id}', file=sys.stderr); raise SystemExit(1)
source_path = str(evidence_row.get('path',''))
allowed_source = source_path in {'docs/ai-instructions.md','CMakePresets.json','CMakeLists.txt'} or source_path.startswith('.agents/skills/') or source_path.startswith('CI/') or source_path.startswith('.github/workflows/')
if not allowed_source:
    print(f'command lock add: evidence path is not an accepted command authority: {source_path}', file=sys.stderr); raise SystemExit(1)
output_path = Path(str(evidence_row.get('output_path','')))
if not output_path.is_file() or hashlib.sha256(output_path.read_bytes()).hexdigest() != evidence_row.get('output_sha256'):
    print(f'command lock add: evidence output integrity failed for {evidence_id}', file=sys.stderr); raise SystemExit(1)
output = output_path.read_text(encoding='utf-8', errors='replace')
if command not in output:
    print('command lock add: exact command is absent from the cited evidence output', file=sys.stderr); raise SystemExit(1)
commit = str(evidence_row.get('commit',''))
if subprocess.run(['git','merge-base','--is-ancestor',commit,'HEAD'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
    print('command lock add: evidence commit is not an ancestor of HEAD', file=sys.stderr); raise SystemExit(1)
path = Path('.agent/state/COMMANDS.lock.tsv')
rows = []
if path.is_file():
    with path.open(encoding='utf-8', newline='') as handle: rows = list(csv.DictReader(handle, delimiter='\t'))
if any(row.get('key') == key and row.get('platform') == platform for row in rows):
    print(f'command lock add: duplicate key/platform {key}/{platform}', file=sys.stderr); raise SystemExit(1)
with path.open('a', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerow([key, command, evidence_id, owner_node, platform, datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')])
print(f'command lock add: ok {key}/{platform}')
