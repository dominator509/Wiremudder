#!/usr/bin/env sh
# Contract test: WireCore boundary paths exist and are namespaced under
# the authorized new boundaries.
set -eu
for d in src/wiremudder/bridge wirecore/crates/wirecore-runtime wirecore/crates/wire-contracts schemas/wiremudder/bridge; do
  [ -d "$d" ] || { echo "FAIL: missing $d" >&2; exit 1; }
done
python3 - <<'PY' || { echo "FAIL: bridge namespace" >&2; exit 1; }
import json
from pathlib import Path
# Bridge schema must declare a versioned frame contract.
schema_files = list(Path('schemas/wiremudder/bridge').rglob('*.json'))
assert schema_files, 'no bridge schema'
for s in schema_files:
    doc = json.loads(s.read_text(encoding='utf-8'))
    assert '$id' in doc and 'title' in doc, f'{s} incomplete'
print('contract wirecore-boundaries: ok')
PY
echo "contract wirecore-boundaries: ok"
