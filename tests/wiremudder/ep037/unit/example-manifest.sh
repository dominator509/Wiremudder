#!/usr/bin/env sh
# EP-037 M2 unit test: the example package manifest is a real, valid
# instance of the canonical package manifest schema.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -f schemas/wiremudder/packages/manifest.schema.json ] || fail "missing schema"
[ -f examples/wiremudder/manifest.example.json ] || fail "missing example manifest"

python3 - "$PWD" <<'PY' || fail "manifest does not validate against schema"
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
schema = json.loads((root / 'schemas/wiremudder/packages/manifest.schema.json').read_text())
manifest = json.loads((root / 'examples/wiremudder/manifest.example.json').read_text())
try:
    import jsonschema
    jsonschema.validate(instance=manifest, schema=schema)
except ImportError:
    # Minimal structural validation: required keys present.
    for k in schema['required']:
        assert k in manifest, f"missing required key {k}"
    perms = schema['properties']['requested_permissions']['items']['enum']
    for p in manifest['requested_permissions']:
        assert p in perms, f"unknown permission {p}"
    assert len(manifest['content_sha256']) == 64
print("manifest ok")
PY

echo "unit EP-037 example-manifest: ok"
