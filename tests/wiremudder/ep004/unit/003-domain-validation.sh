#!/usr/bin/env sh
# Unit test: capability + error + privacy schemas enforce enum domains.
set -eu
python3 - <<'PY' || { echo "FAIL: domain validation" >&2; exit 1; }
import json
from pathlib import Path
cap = json.loads(Path('schemas/wiremudder/capability/capability.schema.json').read_text())
err = json.loads(Path('schemas/wiremudder/error/error.schema.json').read_text())
priv = json.loads(Path('schemas/wiremudder/privacy/privacy.schema.json').read_text())
assert cap['properties']['state']['enum'] == ['uncertified','implemented','certified','disabled']
assert cap['properties']['id']['pattern'] == '^WM-FEAT-[0-9]{4}$'
assert 'rollback' in err['properties']['code']['enum']
assert priv['properties']['classification']['enum'] == ['public','local','private','sensitive','secret']
print('unit domain-validation: ok')
PY
echo "unit domain-validation: ok"
