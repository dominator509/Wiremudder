#!/usr/bin/env python3
from __future__ import annotations

import csv
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f'blueprint validation: FAIL - {message}', file=sys.stderr)
    raise SystemExit(1)


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding='utf-8', newline='') as f:
        return list(csv.DictReader(f, delimiter='\t'))


required = [
    'AGENTS.md', 'COMMANDS.md', 'PREFLIGHT.md', 'PROJECT_BRIEF.md', 'ARCHITECTURE.md',
    'FEATURE_CATALOG.md', 'PERFORMANCE_CONSTITUTION.md', 'WIREMUDDER_SECURITY.md', 'TESTING.md',
    'UPSTREAM.lock.yaml', 'AUTHORITY_CHANGE_PROTOCOL.md', '.agent/AUTHORITY_FILES.tsv', '.agent/MANIFEST.tsv', '.agent/GRAPH.md', '.agent/LOOPS.md', '.agent/state/LEDGER.md',
    '.agent/features/FEATURES.tsv', '.agent/requirements/VALIDATION_MATRIX.tsv',
    '.agent/live-fire/PROOFS.tsv', 'docs/provenance/SOURCE_DOCUMENT_COVERAGE.tsv',
    'docs/provenance/SOURCE_FEATURE_COVERAGE.tsv',
]
for rel in required:
    if not (ROOT / rel).is_file():
        fail(f'missing required file: {rel}')

# ASCII and unresolved output-template checks are scoped to pack-owned manifest files so the validator can run inside the full Mudlet repository.
manifest_rows = read_tsv(ROOT / '.agent/MANIFEST.tsv')
manifest_paths = [ROOT / row['path'] for row in manifest_rows]
for path in sorted(manifest_paths):
    if not path.is_file():
        fail(f'manifest-owned file missing: {path.relative_to(ROOT)}')
    try:
        data = path.read_bytes()
        data.decode('ascii')
    except (UnicodeDecodeError, OSError):
        fail(f'non-ASCII or unreadable blueprint file: {path.relative_to(ROOT)}')
    text = data.decode('ascii')
    if (chr(123) * 2) in text:
        fail(f'unresolved double-brace token: {path.relative_to(ROOT)}')
    if ('.' * 3) in text:
        fail(f'ellipsis or elision token: {path.relative_to(ROOT)}')

# Graph parse and DAG.
graph_text = (ROOT / '.agent/GRAPH.md').read_text(encoding='ascii')
inside = False
nodes: list[str] = []
deps: dict[str, list[str]] = {}
for line in graph_text.splitlines():
    if line == 'GRAPH-TABLE-BEGIN':
        inside = True
        continue
    if line == 'GRAPH-TABLE-END':
        inside = False
        continue
    if inside and line.startswith('NODE '):
        parts = line.split()
        if len(parts) != 4 or parts[2] != 'DEPS':
            fail(f'invalid graph line: {line}')
        node = parts[1]
        if node in deps:
            fail(f'duplicate graph node: {node}')
        nodes.append(node)
        deps[node] = [] if parts[3] == '-' else parts[3].split(',')
if not nodes:
    fail('empty graph')
for node, node_deps in deps.items():
    for dep in node_deps:
        if dep not in deps:
            fail(f'{node} depends on unknown node {dep}')
        if nodes.index(dep) >= nodes.index(node):
            fail(f'graph is not topologically ordered: {node} depends on {dep}')

visiting: set[str] = set()
visited: set[str] = set()
def visit(node: str) -> None:
    if node in visiting:
        fail(f'graph cycle at {node}')
    if node in visited:
        return
    visiting.add(node)
    for dep in deps[node]:
        visit(dep)
    visiting.remove(node)
    visited.add(node)
for node in nodes:
    visit(node)

# Node file parity.
execplans = sorted((ROOT / '.agent/execplans').glob('EP-*.md'))
contracts = sorted((ROOT / '.agent/node-contracts').glob('EP-*.md'))
expected = sorted((ROOT / '.agent/expected-files').glob('EP-???.txt'))
exec_ids = {p.name[:6] for p in execplans}
contract_ids = {p.stem for p in contracts}
expected_ids = {p.stem for p in expected}
if set(nodes) != exec_ids or set(nodes) != contract_ids or set(nodes) != expected_ids:
    fail('graph, ExecPlan, node-contract, and expected-file node sets differ')

sections = [
    '# 1. Purpose and Big Picture', '# 2. Scope', '# 3. Non-goals', '# 4. Context and Orientation',
    '# 5. Files to Read First', '# 6. Expected Changed Files', '# 7. Interfaces and Contracts',
    '# 8. Milestones', '# 9. Validation and Acceptance', '# 10. Idempotence and Recovery',
    '# 11. Progress', '# 12. Surprises and Discoveries', '# 13. Decision Log',
    '# 14. Outcomes and Retrospective',
]
fields = ['GOAL:', 'READ:', 'CHANGE:', 'CONTENT:', 'RUN:', 'EXPECT:', 'EVIDENCE:', 'FALLBACK:', 'COMMIT:']
for path in execplans:
    text = path.read_text(encoding='ascii')
    node = path.name[:6]
    for marker in ['NODE-META-BEGIN', f'ID: {node}', f'VERIFY: sh scripts/node-verify.sh {node}', f'GREEN_TAG: green/{node}', 'NODE-META-END']:
        if marker not in text:
            fail(f'{path.name} missing metadata marker {marker}')
    positions = [text.find(s) for s in sections]
    if any(p < 0 for p in positions) or positions != sorted(positions):
        fail(f'{path.name} missing or misordered required sections')
    for i in range(1, 6):
        match = re.search(rf'^### M{i}:.*?(?=^### M{i+1}:|^# 9\.|\Z)', text, re.M | re.S)
        if not match:
            fail(f'{path.name} missing milestone M{i}')
        block = match.group(0)
        for field in fields:
            if field not in block:
                fail(f'{path.name} M{i} missing {field}')
        if not (ROOT / f'.agent/milestone-files/{node}-M{i}.txt').is_file():
            fail(f'missing milestone path fence for {node} M{i}')

features = read_tsv(ROOT / '.agent/features/FEATURES.tsv')
proofs = read_tsv(ROOT / '.agent/live-fire/PROOFS.tsv')
requirements = read_tsv(ROOT / '.agent/requirements/VALIDATION_MATRIX.tsv')
proof_ids = {r['id'] for r in proofs}
spec_ids = {p.name[:8] for p in (ROOT / '.agent/specs').glob('SPEC-*.md')}
feature_ids: set[str] = set()
for row in features:
    if not all(row.get(k, '').strip() for k in ['id', 'status', 'profile', 'category', 'title', 'source', 'spec', 'node', 'test_path', 'proof']):
        fail(f'incomplete feature row: {row}')
    if row['id'] in feature_ids:
        fail(f'duplicate feature ID: {row["id"]}')
    feature_ids.add(row['id'])
    if row['spec'] not in spec_ids or row['node'] not in deps or row['proof'] not in proof_ids:
        fail(f'invalid feature trace: {row["id"]}')

req_ids: set[str] = set()
for row in requirements:
    if not all(row.get(k, '').strip() for k in ['requirement_id', 'spec_id', 'spec_file', 'node_id', 'verification_class', 'test_path', 'proof_id', 'behavior']):
        fail(f'incomplete requirement row: {row}')
    if row['requirement_id'] in req_ids:
        fail(f'duplicate requirement ID: {row["requirement_id"]}')
    req_ids.add(row['requirement_id'])
    if row['spec_id'] not in spec_ids or row['node_id'] not in deps or row['proof_id'] not in proof_ids:
        fail(f'invalid requirement trace: {row["requirement_id"]}')

for row in proofs:
    if row['node'] not in deps:
        fail(f'proof references unknown node: {row}')

# Adapter block parity.
adapters = [
    'AGENTS.md', 'CLAUDE.md', 'GEMINI.md', 'HERMES.md', 'OPENCLAW.md',
    '.github/copilot-instructions.md', '.cursor/rules/wiremudder-graphlock.mdc',
    '.clinerules/wiremudder-graphlock.md',
]
blocks = []
for rel in adapters:
    text = (ROOT / rel).read_text(encoding='ascii')
    match = re.search(r'PRIME-BLOCK-BEGIN\n.*?\nPRIME-BLOCK-END', text, re.S)
    if not match:
        fail(f'adapter missing prime block: {rel}')
    blocks.append(match.group(0))
if len(set(blocks)) != 1:
    fail('adapter prime blocks differ')

# Source coverage has no empty disposition.
source_rows = read_tsv(ROOT / 'docs/provenance/SOURCE_DOCUMENT_COVERAGE.tsv')
if not source_rows:
    fail('source document coverage is empty')
for row in source_rows:
    if not row['source'] or not row['sha256'] or not row['disposition'] or not row['authoritative_destination']:
        fail(f'incomplete source coverage row: {row}')

# Script syntax and Python compilation for pack-owned scripts only.
for path in sorted(p for p in manifest_paths if p.as_posix().endswith('.sh') and '/scripts/' in ('/' + p.relative_to(ROOT).as_posix())):
    result = subprocess.run(['sh', '-n', str(path)], capture_output=True, text=True)
    if result.returncode != 0:
        fail(f'shell syntax: {path.relative_to(ROOT)}: {result.stderr.strip()}')
for path in sorted(p for p in manifest_paths if p.as_posix().endswith('.py') and '/scripts/' in ('/' + p.relative_to(ROOT).as_posix())):
    try:
        compile(path.read_text(encoding='ascii'), str(path), 'exec')
    except SyntaxError as exc:
        fail(f'python syntax: {path.relative_to(ROOT)}: {exc}')

print('blueprint structure: ok')
