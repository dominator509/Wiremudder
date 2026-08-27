#!/usr/bin/env sh
# Unit test: telemetry event schema accepts valid events and rejects
# invalid ones (fail-closed canonical validation).
set -eu
python3 - <<'PY' || { echo "FAIL: telemetry validation" >&2; exit 1; }
import json
from pathlib import Path
schema = json.loads(Path('schemas/wiremudder/telemetry/event.schema.json').read_text())
# Minimal structural validation per the schema's required fields.
def check(doc):
    req = schema['required']
    for r in req:
        assert r in doc, f'missing {r}'
    assert doc['schema_version'] == 1
    assert doc['severity'] in schema['properties']['severity']['enum']
    assert doc['subsystem'] in schema['properties']['subsystem']['enum']
    assert doc['priority'] in schema['properties']['priority']['enum'], 'priority'
    assert len(doc['event_id']) >= 8
    if 'feature' in doc:
        import re
        assert re.match(r'^WM-FEAT-[0-9]{4}$', doc['feature']), doc['feature']
valid = {
    'schema_version': 1, 'event_id': 'evt-12345', 't': 1720000000000,
    'subsystem': 'lua', 'severity': 'info', 'fingerprint': 'abc123',
    'priority': 'P3', 'feature': 'WM-FEAT-0126',
}
check(valid)
# invalid priority must fail
bad = dict(valid); bad['priority'] = 'P9'
try:
    check(bad); raise SystemExit('P9 accepted')
except AssertionError:
    pass
# invalid subsystem must fail
bad2 = dict(valid); bad2['subsystem'] = 'nonsense'
try:
    check(bad2); raise SystemExit('bad subsystem accepted')
except AssertionError:
    pass
print('unit telemetry-validation: ok')
PY
echo "unit telemetry-validation: ok"
