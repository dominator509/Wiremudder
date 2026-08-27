#!/usr/bin/env python3
"""Generate upstream-tree.tsv for EP-000 M2 (test fixture + artifact).

Read-only inventory of every tracked path at the pinned baseline:
path, blob/tree type, mode, size, and blob sha256. Schema version 1.
"""
from __future__ import annotations
import hashlib, subprocess, sys
from pathlib import Path

ROOT = Path.cwd()
OUT = ROOT / '.agent/state/upstream-tree.tsv'
env = {}
if (ROOT / '.env').is_file():
    for raw in (ROOT / '.env').read_text(encoding='utf-8').splitlines():
        if '=' in raw and not raw.lstrip().startswith('#'):
            k, v = raw.split('=', 1)
            env[k.strip()] = v.strip()
commit = env.get('WIREMUDDER_UPSTREAM_COMMIT', '').strip()
if not commit:
    print('upstream-tree: WIREMUDDER_UPSTREAM_COMMIT is required', file=sys.stderr)
    raise SystemExit(1)

proc = subprocess.run(
    ['git', 'ls-tree', '-r', '-l', commit],
    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
)
if proc.returncode != 0:
    print(proc.stdout, end='', file=sys.stderr)
    raise SystemExit(proc.returncode)

rows = []
for line in proc.stdout.splitlines():
    # format: <mode> <type> <oid> <size><TAB><path>
    if '\t' not in line:
        continue
    meta, path = line.split('\t', 1)
    mparts = meta.split()
    if len(mparts) != 4:
        continue
    mode, otype, oid, size = mparts
    try:
        size_int = int(size) if size != '-' else 0
    except ValueError:
        size_int = 0
    rows.append((path, otype, mode, size_int, oid))

rows.sort(key=lambda r: r[0])
OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open('w', encoding='utf-8') as handle:
    handle.write('path\ttype\tmode\tsize\tblob_sha\n')
    for path, otype, mode, size_int, oid in rows:
        blob_sha = ''
        if otype == 'blob':
            try:
                blob = subprocess.run(
                    ['git', 'cat-file', 'blob', oid],
                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                ).stdout
                blob_sha = hashlib.sha256(blob).hexdigest()
            except Exception:
                blob_sha = ''
        handle.write(f'{path}\t{otype}\t{mode}\t{size_int}\t{blob_sha}\n')

print(f'upstream-tree: ok paths={len(rows)} commit={commit}')
