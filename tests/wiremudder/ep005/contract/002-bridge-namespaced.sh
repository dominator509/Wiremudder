#!/usr/bin/env sh
# Contract test: the C++ bridge is a NEW namespaced boundary (no
# inherited source edits since lease base).
set -eu
python3 - <<'PY' || { echo "FAIL: inherited edits" >&2; exit 1; }
import re
base = ''
for line in open('.agent/state/LEDGER.md', encoding='utf-8'):
    parts = line.split(' | ', 4)
    if len(parts) == 5 and parts[2] == 'EP-005' and parts[3] in {'LEASE', 'LEASE_TAKEOVER'}:
        m = re.search(r'\bbase=([0-9a-f]{40})\b', parts[4])
        if m:
            base = m.group(1)
assert base, 'no lease base'
import subprocess
changed = subprocess.run(['git','diff','--name-only',base+'..HEAD'], text=True, stdout=subprocess.PIPE).stdout.splitlines()
allowed = (
    'src/wiremudder/', 'wirecore/', 'schemas/wiremudder/bridge/', 'tests/wiremudder/ep005/',
    'tests/live-fire/', 'docs/wiremudder/bridge/', 'scripts/', '.agent/', 'tools/schema-bindings/',
)
bad = [f for f in changed if f and not any(f.startswith(p) or f == p.rstrip('/') for p in allowed)]
assert not bad, f'out-of-boundary changes: {bad}'
print('contract bridge-namespaced: ok')
PY
echo "contract bridge-namespaced: ok"
