#!/usr/bin/env sh
# Contract test: secrets and consent requirements are bound in the
# node contract and the egress/consent schemas enforce denial-first
# and scoped-revocable semantics.
set -eu

cd "$(dirname "$0")/../../../.."

python3 - <<'PY' || { echo "FAIL: secrets/consent contract" >&2; exit 1; }
import json, re
from pathlib import Path

contract = Path('.agent/node-contracts/EP-006.md').read_text(encoding='utf-8')
# The contract must bind the owned secret/consent requirements.
for req in ['WM-SPEC-010-R06', 'WM-SPEC-010-R07', 'WM-SPEC-010-R09', 'WM-SPEC-011-R01']:
    assert req in contract, f'contract missing {req}'

# Consent schema: revocable, scoped, versioned, tied to time.
consent = json.loads(Path('schemas/wiremudder/privacy/consent-receipt.schema.json').read_text())
props = consent['properties']
assert props['revocable']['const'] is True, 'consent must be revocable'
assert 'revoked_at' in props, 'consent missing revocation'
assert 'granted_at' in props and props['granted_at']['format'] == 'date-time'
assert 'consent_version' in props, 'consent missing version'
assert 'data_class' in props and 'enum' in props['data_class']

# Egress schema: denial-first lockdown with user-visible overrides only.
egress = json.loads(Path('schemas/wiremudder/privacy/egress-policy.schema.json').read_text())
assert egress['properties']['lockdown']['type'] == 'boolean'
ov = egress['properties']['overrides']['items']['properties']
assert ov['user_visible']['const'] is True, 'overrides must be user-visible'
assert 'consent_receipt_id' in ov, 'override must reference consent'
print('contract secrets-consent-boundary: ok')
PY
echo "contract secrets-consent-boundary: ok"
