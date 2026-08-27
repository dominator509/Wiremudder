#!/usr/bin/env sh
# Contract test: replay and museum boundaries are reserved for WireMudder
# namespaced code. Compares against the EP-003 lease base (the scope
# audit authority) rather than the upstream baseline.
set -eu
python3 - <<'PY' || { echo "FAIL: namespace drift" >&2; exit 1; }
import json, re, subprocess
base = ''
for line in open('.agent/state/LEDGER.md', encoding='utf-8'):
    parts = line.split(' | ', 4)
    if len(parts) == 5 and parts[2] == 'EP-003' and parts[3] in {'LEASE', 'LEASE_TAKEOVER'}:
        m = re.search(r'\bbase=([0-9a-f]{40})\b', parts[4])
        if m:
            base = m.group(1)
assert base, 'no lease base for EP-003'
allowed = (
    'compatibility/', 'schemas/wiremudder/', 'tests/wiremudder/', 'tests/live-fire/',
    'tools/protocol-museum/', 'docs/wiremudder/', 'scripts/', '.agent/',
)
new = subprocess.run(['git','diff','--name-only',base+'..HEAD'], text=True, stdout=subprocess.PIPE).stdout.splitlines()
bad = [f for f in new if f and not any(f == p or f.startswith(p) for p in allowed)]
assert not bad, f'non-namespaced since lease base: {bad}'
print('contract ep003-namespacing: ok')
PY
echo "contract ep003-namespacing: ok"
