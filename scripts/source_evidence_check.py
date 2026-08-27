#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, re, subprocess, sys
from pathlib import Path

ROOT = Path.cwd(); ledger = ROOT / '.agent/state/source-evidence.jsonl'
if not ledger.is_file():
    print('source evidence check: FAIL - missing ledger', file=sys.stderr); raise SystemExit(1)
required = {'schema_version','evidence_id','observed_at','repository','commit','path','symbol_or_range','claim','command','exit_code','output_path','output_sha256','agent_id'}
seen: set[str] = set(); rows = 0
for lineno, raw in enumerate(ledger.read_text(encoding='utf-8').splitlines(), 1):
    if not raw.strip(): continue
    try: row = json.loads(raw)
    except json.JSONDecodeError as exc:
        print(f'source evidence check: FAIL - invalid JSON line {lineno}: {exc}', file=sys.stderr); raise SystemExit(1)
    missing = required - set(row)
    if missing:
        print(f'source evidence check: FAIL - line {lineno} missing {sorted(missing)}', file=sys.stderr); raise SystemExit(1)
    eid = str(row['evidence_id'])
    if not re.fullmatch(r'WM-SRC-\d{6}', eid) or eid in seen:
        print(f'source evidence check: FAIL - invalid or duplicate ID {eid}', file=sys.stderr); raise SystemExit(1)
    seen.add(eid); rows += 1
    if row['exit_code'] != 0 or not isinstance(row['command'], list) or not row['command']:
        print(f'source evidence check: FAIL - invalid command result {eid}', file=sys.stderr); raise SystemExit(1)
    commit = str(row['commit']); path = str(row['path'])
    if subprocess.run(['git','cat-file','-e',commit + '^{commit}'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
        print(f'source evidence check: FAIL - unknown commit {commit}', file=sys.stderr); raise SystemExit(1)
    if subprocess.run(['git','cat-file','-e',f'{commit}:{path}'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
        print(f'source evidence check: FAIL - path absent at evidence commit {eid}: {path}', file=sys.stderr); raise SystemExit(1)
    output_path = ROOT / str(row['output_path'])
    if not output_path.is_file() or hashlib.sha256(output_path.read_bytes()).hexdigest() != row['output_sha256']:
        print(f'source evidence check: FAIL - output hash mismatch {eid}', file=sys.stderr); raise SystemExit(1)
print(f'source evidence check: ok rows={rows}')
