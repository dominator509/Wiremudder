#!/usr/bin/env sh
# Contract test: EP-006 privacy boundaries are declared and the
# interface schemas exist and validate the owned privacy contracts.
set -eu

cd "$(dirname "$0")/../../../.."

# 1. Node contract authorizes the four new boundaries.
for d in src/wiremudder/privacy wirecore/crates/wire-privacy wirecore/crates/wire-secrets schemas/wiremudder/privacy; do
  grep -q "$d" .agent/node-contracts/EP-006.md || { echo "FAIL: boundary $d missing from contract" >&2; exit 1; }
done

# 2. Interface schemas exist and declare the privacy contracts.
python3 - <<'PY' || { echo "FAIL: privacy schema contract" >&2; exit 1; }
import json
from pathlib import Path
base = Path('schemas/wiremudder/privacy')
need = {
    'consent-receipt.schema.json': 'consent_version',
    'egress-policy.schema.json': 'lockdown',
    'redaction-policy.schema.json': 'default_deny',
}
for name, key in need.items():
    p = base / name
    assert p.is_file(), f'missing {name}'
    doc = json.loads(p.read_text(encoding='utf-8'))
    assert '$id' in doc and 'title' in doc, f'{name} incomplete'
    assert key in doc['properties'], f'{name} missing {key}'
print('contract privacy-boundaries: ok')
PY
echo "contract privacy-boundaries: ok"
