#!/usr/bin/env python3
from __future__ import annotations
import json, os, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path.cwd()
if len(sys.argv) != 7:
    print('usage: discovered_path_add.py EP-XXX EVIDENCE_ID PATH RATIONALE TEST_PATH ROLLBACK', file=sys.stderr); raise SystemExit(2)
node, evidence_id, path_text, rationale, test_text, rollback = sys.argv[1:]
if not re.fullmatch(r'EP-\d{3}', node):
    print('discovered path add: invalid node', file=sys.stderr); raise SystemExit(2)
path = Path(path_text); test_path = Path(test_text)
if path.is_absolute() or '..' in path.parts or path_text.endswith('/') or not path_text:
    print('discovered path add: PATH must be one exact inherited file', file=sys.stderr); raise SystemExit(1)
for prefix in ('.agent/','scripts/','docs/wiremudder/','wirecore/','schemas/wiremudder/','tests/wiremudder/','src/wiremudder/'):
    if path_text.startswith(prefix):
        print(f'discovered path add: {path_text} belongs in the static fence, not a brownfield amendment', file=sys.stderr); raise SystemExit(1)
if not path.is_file() or subprocess.run(['git','ls-files','--error-unmatch','--',path_text], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
    print(f'discovered path add: inherited file is not tracked: {path_text}', file=sys.stderr); raise SystemExit(1)
for args in (['diff','--quiet','--',path_text], ['diff','--cached','--quiet','--',path_text]):
    if subprocess.run(['git',*args]).returncode != 0:
        print(f'discovered path add: inherited file must be clean before authorization: {path_text}', file=sys.stderr); raise SystemExit(1)
if not test_path.is_file() or not (test_text.startswith('tests/wiremudder/') or test_text.startswith('compatibility/')):
    print('discovered path add: TEST_PATH must be an existing independent WireMudder test or compatibility fixture', file=sys.stderr); raise SystemExit(1)
if len(rationale.strip()) < 20 or len(rollback.strip()) < 10:
    print('discovered path add: rationale or rollback is too weak', file=sys.stderr); raise SystemExit(1)
ledger = ROOT / '.agent/state/source-evidence.jsonl'; evidence = None
if ledger.is_file():
    for raw in ledger.read_text(encoding='utf-8').splitlines():
        if raw.strip():
            row = json.loads(raw)
            if row.get('evidence_id') == evidence_id: evidence = row; break
if not evidence:
    print(f'discovered path add: unknown evidence ID {evidence_id}', file=sys.stderr); raise SystemExit(1)
if evidence.get('path') != path_text:
    print('discovered path add: source evidence must name the exact inherited file', file=sys.stderr); raise SystemExit(1)
commit = str(evidence.get('commit',''))
if subprocess.run(['git','merge-base','--is-ancestor',commit,'HEAD']).returncode != 0:
    print('discovered path add: evidence commit is not an ancestor of HEAD', file=sys.stderr); raise SystemExit(1)
target = ROOT / f'.agent/expected-files/{node}.discovered.txt'
existing = []
if target.is_file():
    for raw in target.read_text(encoding='utf-8').splitlines():
        if raw.strip() and not raw.lstrip().startswith('#'): existing.append(json.loads(raw))
if any(row.get('path') == path_text for row in existing):
    print(f'discovered path add: duplicate path {path_text}', file=sys.stderr); raise SystemExit(1)
record = {
    'node': node,
    'source_evidence_id': evidence_id,
    'repository_commit': commit,
    'path': path_text,
    'rationale': rationale.strip(),
    'test': test_text,
    'rollback': rollback.strip(),
    'added_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'agent_id': os.environ.get('WIREMUDDER_AGENT_ID','unknown-agent'),
}
with target.open('a', encoding='utf-8') as handle:
    handle.write(json.dumps(record, sort_keys=True, separators=(',', ':')) + '\n')
agent = record['agent_id']
subprocess.run(['sh','scripts/ledger.sh','append',agent,node,'HEARTBEAT',f'discovered_path={path_text} evidence={evidence_id}'], check=True)
print(f'discovered path add {node}: ok {path_text}')
