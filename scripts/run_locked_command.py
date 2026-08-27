#!/usr/bin/env python3
from __future__ import annotations
import csv, os, subprocess, sys
from pathlib import Path
if len(sys.argv) != 2:
    print('usage: run_locked_command.py KEY', file=sys.stderr); raise SystemExit(2)
key = sys.argv[1]; path = Path('.agent/state/COMMANDS.lock.tsv')
check = subprocess.run(['python3','scripts/command_lock_check.py'], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
if check.returncode != 0:
    print(check.stdout, end='', file=sys.stderr)
    print('locked command: command lock integrity failed', file=sys.stderr); raise SystemExit(check.returncode)
if not path.is_file():
    print('locked command: missing .agent/state/COMMANDS.lock.tsv; EP-000 must create it from source evidence', file=sys.stderr); raise SystemExit(1)
with path.open(encoding='utf-8', newline='') as f:
    rows = list(csv.DictReader(f, delimiter='\t'))
platform = os.environ.get('WIREMUDDER_PLATFORM','').strip().lower()
if not platform:
    if sys.platform.startswith('win'): platform = 'windows'
    elif sys.platform == 'darwin': platform = 'macos'
    else: platform = 'linux'
match = [r for r in rows if r.get('key') == key and r.get('platform') in {platform, 'all'}]
exact = [r for r in match if r.get('platform') == platform]
if exact: match = exact
if len(match) != 1 or not match[0].get('command','').strip() or not match[0].get('evidence_id','').strip():
    print(f'locked command: missing or ambiguous key {key} for platform {platform}', file=sys.stderr); raise SystemExit(1)
env = os.environ.copy(); env.update({'CI':'true','GIT_TERMINAL_PROMPT':'0','GIT_PAGER':'cat','PAGER':'cat','DEBIAN_FRONTEND':'noninteractive'})
raise SystemExit(subprocess.run(['sh','-lc',match[0]['command']], env=env).returncode)
