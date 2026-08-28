#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, os, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path.cwd()
LEDGER = ROOT / '.agent/state/source-evidence.jsonl'
LOG_DIR = ROOT / '.agent/state/source-evidence'


def fail(message: str, code: int = 1) -> None:
    print(f'source evidence: FAIL - {message}', file=sys.stderr)
    raise SystemExit(code)


def git_output(args: list[str]) -> str:
    try:
        return subprocess.check_output(['git', *args], text=True, stderr=subprocess.STDOUT).strip()
    except subprocess.CalledProcessError as exc:
        fail(f'git command failed: git {" ".join(args)}: {exc.output.strip()}')


if '--' not in sys.argv or sys.argv.index('--') < 4:
    fail('usage: source_evidence.py PATH SYMBOL_OR_RANGE CLAIM -- COMMAND ARGS', 2)
sep = sys.argv.index('--')
path_text, symbol, claim = sys.argv[1:4]
command = sys.argv[sep + 1:]
if not command:
    fail('missing evidence command', 2)
path = Path(path_text)
if path.is_absolute() or '..' in path.parts or not path_text or path_text.endswith('/'):
    fail('PATH must be one exact repository file')
if not path.is_file():
    fail(f'PATH is not a file: {path_text}')
if not symbol.strip() or not claim.strip():
    fail('symbol/range and claim are required')
if subprocess.run(['git', 'ls-files', '--error-unmatch', '--', path_text], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
    fail(f'PATH is not tracked at HEAD: {path_text}')
for args in (['diff', '--quiet', '--', path_text], ['diff', '--cached', '--quiet', '--', path_text]):
    if subprocess.run(['git', *args]).returncode != 0:
        fail(f'PATH must be clean before evidence is recorded: {path_text}')
status_before = git_output(['status', '--porcelain=v1', '--untracked-files=all'])
commit = git_output(['rev-parse', 'HEAD'])
repo = os.environ.get('WIREMUDDER_UPSTREAM_REPO', '').strip()
if not repo:
    proc = subprocess.run(['git', 'config', '--get', 'remote.upstream.url'], text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    repo = proc.stdout.strip()
if not repo:
    proc = subprocess.run(['git', 'config', '--get', 'remote.origin.url'], text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    repo = proc.stdout.strip()
if not repo:
    fail('repository URL is unavailable')
proc = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
output = proc.stdout
status_after = git_output(['status', '--porcelain=v1', '--untracked-files=all'])
if status_after != status_before:
    fail('evidence command changed repository state; restore the tree and use a read-only command')
if proc.returncode != 0:
    print(output, end='')
    fail(f'evidence command exited {proc.returncode}')
LEDGER.parent.mkdir(parents=True, exist_ok=True)
LOG_DIR.mkdir(parents=True, exist_ok=True)
existing: list[dict[str, object]] = []
if LEDGER.exists():
    for line in LEDGER.read_text(encoding='utf-8').splitlines():
        if line.strip():
            existing.append(json.loads(line))
for row in existing:
    if row.get('commit') == commit and row.get('path') == path_text and row.get('symbol_or_range') == symbol and row.get('claim') == claim and row.get('command') == command:
        print(str(row['evidence_id']))
        raise SystemExit(0)
# Allocate the next evidence ID by scanning existing IDs, never by
# len()+1: renumbered or repaired ledgers have gaps and would collide.
max_id = 0
for row in existing:
    m = re.fullmatch(r'WM-SRC-(\d{6})', str(row.get('evidence_id', '')))
    if m:
        max_id = max(max_id, int(m.group(1)))
evidence_id = f'WM-SRC-{max_id + 1:06d}'
log_rel = f'.agent/state/source-evidence/{evidence_id}.log'
log_path = ROOT / log_rel
log_path.write_text(output, encoding='utf-8')
record = {
    'schema_version': 2,
    'evidence_id': evidence_id,
    'observed_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'repository': repo,
    'commit': commit,
    'path': path_text,
    'symbol_or_range': symbol,
    'claim': claim,
    'command': command,
    'exit_code': proc.returncode,
    'output_path': log_rel,
    'output_sha256': hashlib.sha256(output.encode('utf-8')).hexdigest(),
    'agent_id': os.environ.get('WIREMUDDER_AGENT_ID', 'unknown-agent'),
}
with LEDGER.open('a', encoding='utf-8') as handle:
    handle.write(json.dumps(record, sort_keys=True, separators=(',', ':')) + '\n')
print(evidence_id)
