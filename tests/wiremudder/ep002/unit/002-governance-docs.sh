#!/usr/bin/env sh
# Unit test: governance documents encode the required invariants.
set -eu
python3 - <<'PY' || { echo "FAIL: governance invariants" >&2; exit 1; }
from pathlib import Path
import re
sync = Path('UPSTREAM_SYNC_POLICY.md').read_text(encoding='utf-8')
for token in ('sync', 'branch', 'rollback', 'gate'):
    assert token.lower() in sync.lower(), f'missing {token} in sync policy'
brand = Path('BRANDING_POLICY.md').read_text(encoding='utf-8')
for token in ('mass class renames', 'attribution', 'rollback'):
    assert token.lower() in brand.lower(), f'missing {token} in branding policy'
license_strat = Path('LICENSE_STRATEGY.md').read_text(encoding='utf-8')
for token in ('compatible open-source terms', 'STOP condition'):
    assert token.lower() in license_strat.lower(), f'missing {token} in license strategy'
print('unit governance-docs: ok')
PY
echo "unit governance-docs: ok"
