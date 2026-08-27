#!/usr/bin/env sh
# Contract test: EP-008 authorizes the four new boundaries and binds
# every owned requirement in the node contract.
set -eu

cd "$(dirname "$0")/../../../.."

# 1. Node contract authorizes the four new boundaries.
for d in src/wiremudder/command-safety wirecore/crates/wire-actions \
         wirecore/crates/wire-policy schemas/wiremudder/actions; do
  grep -q "$d" .agent/node-contracts/EP-008.md || { echo "FAIL: boundary $d missing from contract" >&2; exit 1; }
done

# 2. All owned requirements are bound in the contract.
python3 - <<'PY' || { echo "FAIL: owned requirements binding" >&2; exit 1; }
from pathlib import Path
contract = Path('.agent/node-contracts/EP-008.md').read_text(encoding='utf-8')
owned = [
    'WM-SPEC-004-R01', 'WM-SPEC-004-R02', 'WM-SPEC-004-R09', 'WM-SPEC-004-R11',
    'WM-SPEC-009-R01', 'WM-SPEC-009-R03', 'WM-SPEC-009-R05', 'WM-SPEC-009-R06',
    'WM-SPEC-009-R07', 'WM-SPEC-009-R08', 'WM-SPEC-009-R09', 'WM-SPEC-009-R10',
    'WM-SPEC-015-R03', 'WM-SPEC-015-R05', 'WM-SPEC-017-R03', 'WM-SPEC-017-R08',
    'WM-SPEC-022-R04', 'WM-SPEC-022-R10',
]
for req in owned:
    assert req in contract, f'contract missing {req}'
print('contract boundaries-requirements: ok')
PY

echo "contract boundaries-requirements: ok"
