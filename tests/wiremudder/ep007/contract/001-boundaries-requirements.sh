#!/usr/bin/env sh
# Contract test: EP-007 authorizes the four new boundaries and binds
# the owned requirements in the node contract.
set -eu

cd "$(dirname "$0")/../../../.."

# 1. Node contract authorizes the four new boundaries.
for d in src/wiremudder/profiles src/wiremudder/routing wirecore/crates/wire-profiles wirecore/crates/wire-routing; do
  grep -q "$d" .agent/node-contracts/EP-007.md || { echo "FAIL: boundary $d missing from contract" >&2; exit 1; }
done

# 2. All owned requirements are bound in the contract.
python3 - <<'PY' || { echo "FAIL: owned requirements binding" >&2; exit 1; }
from pathlib import Path
contract = Path('.agent/node-contracts/EP-007.md').read_text(encoding='utf-8')
owned = [
    'WM-SPEC-006-R04', 'WM-SPEC-006-R05', 'WM-SPEC-006-R06', 'WM-SPEC-006-R08',
    'WM-SPEC-006-R09', 'WM-SPEC-010-R01', 'WM-SPEC-017-R01', 'WM-SPEC-017-R05',
    'WM-SPEC-017-R07', 'WM-SPEC-017-R09', 'WM-SPEC-023-R01',
]
for req in owned:
    assert req in contract, f'contract missing {req}'
print('contract boundaries-requirements: ok')
PY

# 3. The versioned profile contract and no-silent-fallback declaration exist.
grep -q "versioned profile contract" .agent/node-contracts/EP-007.md || { echo "FAIL: versioned profile contract not declared" >&2; exit 1; }
grep -q "never silently falls back to direct" .agent/specs/SPEC-006-network-protocol-and-routing.md || { echo "FAIL: no-silent-fallback not in SPEC-006" >&2; exit 1; }

echo "contract boundaries-requirements: ok"
