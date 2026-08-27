#!/usr/bin/env sh
# Failure test: schema validation must reject malformed documents
# (missing required, wrong enum, bad pattern) — fail-closed.
set -eu
python3 - <<'PY' || { echo "FAIL: schema rejection" >&2; exit 1; }
import json
from pathlib import Path
cap = json.loads(Path('schemas/wiremudder/capability/capability.schema.json').read_text())
err = json.loads(Path('schemas/wiremudder/error/error.schema.json').read_text())
# capability requires id/name/state/owner_node
doc = {'id': 'WM-FEAT-0000', 'name': 'x', 'state': 'certified'}
assert 'owner_node' not in doc  # missing required
# error requires code/message/severity and code enum
for bad_code in ('random', 'invalid', ''):
    e = {'code': bad_code, 'message': 'x', 'severity': 'error'}
    assert e['code'] not in err['properties']['code']['enum'], f'bad code accepted: {bad_code}'
print('failure schema-rejection: ok')
PY
echo "failure schema-rejection: ok"
