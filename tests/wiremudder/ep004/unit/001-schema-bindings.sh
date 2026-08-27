#!/usr/bin/env sh
# Unit test: all canonical schemas parse, declare meta fields, and the
# binding manifest is generated and consistent.
set -eu
python3 tools/schema-bindings/generate_bindings.py
python3 - <<'PY' || { echo "FAIL: manifest" >&2; exit 1; }
import json
from pathlib import Path
m = json.loads(Path('tools/schema-bindings/bindings.manifest.json').read_text())
assert m['count'] >= 6, m
paths = {s['path'] for s in m['schemas']}
assert any('telemetry' in p for p in paths), 'telemetry schema missing'
assert any('capability' in p for p in paths), 'capability schema missing'
assert any('error' in p for p in paths), 'error schema missing'
assert any('privacy' in p for p in paths), 'privacy schema missing'
assert any('profile' in p for p in paths), 'profile schema missing'
assert any('replay' in p for p in paths), 'replay schema missing'
for s in m['schemas']:
    assert s['id'].startswith('https://wiremudder.dev/schemas/'), s
print('unit schema-bindings: ok')
PY
echo "unit schema-bindings: ok"
