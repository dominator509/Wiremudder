#!/usr/bin/env sh
# Contract test: the route-type taxonomy is explicit and user-owned,
# future route types are research-gated, AI cannot touch routing, and
# no abuse-oriented routing behavior is authorized.
set -eu

cd "$(dirname "$0")/../../../.."

python3 - <<'PY' || { echo "FAIL: route taxonomy contract" >&2; exit 1; }
from pathlib import Path
spec = Path('.agent/specs/SPEC-006-network-protocol-and-routing.md').read_text(encoding='utf-8')
contract = Path('.agent/node-contracts/EP-007.md').read_text(encoding='utf-8')

# 1. Explicit user-owned route taxonomy (WM-SPEC-006-R04): direct/system,
#    SOCKS5, HTTP CONNECT, SOCKS4a, Tor local SOCKS, SSH dynamic, VPN metadata.
for token in ['SOCKS5', 'SOCKS4a', 'HTTP CONNECT', 'Tor', 'SSH dynamic', 'VPN']:
    assert token in spec, f'SPEC-006 missing route type {token}'

# 2. Future route types remain research-gated (WM-SPEC-006-R05): the
#    features are marked research-decision-required in the feature catalog.
feats = Path('.agent/features/FEATURES.tsv').read_text(encoding='utf-8')
for fid in ['WM-FEAT-0088', 'WM-FEAT-0089', 'WM-FEAT-0090']:
    for line in feats.splitlines():
        if line.startswith(fid + '\t'):
            assert 'research-decision-required' in line, f'{fid} not research-gated'

# 3. AI and automation cannot create/rotate/select/modify routing profiles
#    or profile routing defaults (WM-SPEC-006-R08).
assert 'cannot create, rotate, select, modify, or overwrite routing profiles' in spec, 'R08 not bound in SPEC-006'
assert 'AI' in contract or 'automation' in contract, 'contract missing AI/automation restriction'

# 4. No abuse-oriented routing behavior (WM-SPEC-006-R09).
assert 'ban or terms-of-service evasion' in spec, 'R09 not bound in SPEC-006'

# 5. Acceptance obligations: selected-route failure never silently becomes
#    direct; egress verification is user-triggered.
for token in ['never silently becomes direct', 'user-triggered', 'routing audit']:
    assert token in contract, f'contract missing acceptance obligation {token}'
print('contract route-taxonomy: ok')
PY

echo "contract route-taxonomy: ok"
