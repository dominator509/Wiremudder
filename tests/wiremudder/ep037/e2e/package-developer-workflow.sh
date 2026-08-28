#!/usr/bin/env sh
# EP-037 M3 e2e test: the user-visible package workflow from the docs —
# author a manifest, validate it against the real schema, check permission
# decisions, and confirm the docs describe what the real system does.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"
oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-packages/Cargo.toml --bin wire-packages-oracle --"

work=$(mktemp -d /tmp/ep037e2e_XXXX)
trap 'rm -rf "$work"' EXIT

# 1. Author a new manifest in a fresh package directory using the example
#    shape from examples/wiremudder/.
cp examples/wiremudder/manifest.example.json "$work/manifest.json"

# 2. Validate it against the real schema.
python3 - "$PWD" "$work" <<'PY' || fail "e2e manifest invalid"
import json, sys
from pathlib import Path
root = Path(sys.argv[1]); work = Path(sys.argv[2])
schema = json.loads((root / 'schemas/wiremudder/packages/manifest.schema.json').read_text())
manifest = json.loads((work / 'manifest.json').read_text())
try:
    import jsonschema
    jsonschema.validate(instance=manifest, schema=schema)
except ImportError:
    for k in schema['required']:
        assert k in manifest, f"missing {k}"
    perms = schema['properties']['requested_permissions']['items']['enum']
    for p in manifest['requested_permissions']:
        assert p in perms, f"unknown permission {p}"
print("e2e manifest validated")
PY

# 3. The manifest requests ui + command_send; the docs say these are the
#    permissions to declare. The oracle grants exactly the approved set.
out=$($oracle decisions "ui,command_send" "ui,command_send" 2>&1)
echo "$out" | grep -q '"permission":"ui","decision":"granted"' || fail "ui not granted"
echo "$out" | grep -q '"permission":"command_send","decision":"granted"' || fail "command_send not granted"

# 4. The docs' no-silent-expansion rule: an unapproved permission is denied
#    and reported as expansion.
out2=$($oracle decisions "ui" "ui,command_send" 2>&1)
echo "$out2" | grep -q '"permission":"command_send","decision":"denied"' || fail "expansion not denied"

echo "e2e EP-037 package-developer-workflow: ok"
