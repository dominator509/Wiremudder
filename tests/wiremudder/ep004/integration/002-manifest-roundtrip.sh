#!/usr/bin/env sh
# Integration test: schema manifest round-trips — regenerate bindings and
# confirm the manifest is deterministic and matches the schema tree.
set -eu
python3 - <<'PY' || { echo "FAIL: manifest roundtrip" >&2; exit 1; }
import hashlib, subprocess
from pathlib import Path
before = hashlib.sha256(Path('tools/schema-bindings/bindings.manifest.json').read_bytes()).hexdigest()
subprocess.run(['python3','tools/schema-bindings/generate_bindings.py'], check=True)
after = hashlib.sha256(Path('tools/schema-bindings/bindings.manifest.json').read_bytes()).hexdigest()
assert before == after, 'manifest not deterministic'
import json
m = json.loads(Path('tools/schema-bindings/bindings.manifest.json').read_text())
assert m['count'] == len(list(Path('schemas/wiremudder').rglob('*.schema.json')))
print('integration manifest-roundtrip: ok')
PY
echo "integration manifest-roundtrip: ok"
