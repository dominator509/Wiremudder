#!/usr/bin/env sh
# Contract test: canonical schema namespace is reserved for WireMudder
# schemas; every existing schema declares $id, title, and type.
# (The >=4 schema count is enforced by the M2 verifier, since the
# additional canonical schemas are authored in M2.)
set -eu
python3 - <<'PY' || { echo "FAIL: schema namespace" >&2; exit 1; }
import json
from pathlib import Path
ns = Path('schemas/wiremudder')
assert ns.is_dir(), 'schemas/wiremudder missing'
schemas = sorted(ns.rglob('*.schema.json'))
assert schemas, 'no schema present'
for s in schemas:
    doc = json.loads(s.read_text(encoding='utf-8'))
    assert '$id' in doc, f'{s}: missing $id'
    assert 'title' in doc, f'{s}: missing title'
    assert 'type' in doc, f'{s}: missing type'
    assert str(s).startswith('schemas/wiremudder/'), f'{s}: outside namespace'
print(f'contract schema-namespace: ok schemas={len(schemas)}')
PY
echo "contract schema-namespace: ok"
