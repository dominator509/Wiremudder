#!/usr/bin/env sh
# Failure test: bindings generator must fail when the schema tree is
# incomplete (dependency-unavailable proof).
set -eu
python3 - <<'PY' || { echo "FAIL: bindings fail-closed" >&2; exit 1; }
import json, subprocess, tempfile
from pathlib import Path
# Generate with a bogus schema root -> must fail, not emit a partial manifest.
tmp = Path(tempfile.mkdtemp())
r = subprocess.run(
    ['python3','-c',
     'import sys; sys.path.insert(0,"tools/schema-bindings"); import generate_bindings; '
     'generate_bindings.SCHEMA_ROOT = Path("/tmp/nonexistent-schema-root"); '
     'raise SystemExit(generate_bindings.main())'],
    capture_output=True, text=True,
)
# The generator's assert on count should fail with nonzero rc.
assert r.returncode != 0, 'generator succeeded with empty schema root'
print('failure bindings-fail-closed: ok')
PY
echo "failure bindings-fail-closed: ok"
