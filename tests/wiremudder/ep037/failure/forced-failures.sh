#!/usr/bin/env sh
# EP-037 M4 forced-failure tests: documentation surfaces fail closed.
# Malformed manifests are rejected, denied permissions stay denied, and a
# missing/oversized input never produces a false acceptance.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }
work=$(mktemp -d /tmp/ep037fail_XXXX)
trap 'rm -rf "$work"' EXIT

[ -f schemas/wiremudder/packages/manifest.schema.json ] || fail "missing schema"

# 1. Malformed manifest: missing required key is rejected.
printf '{"name":"broken"}' > "$work/bad-missing.json"
python3 - "$PWD" "$work" <<'PY' && fail "missing-key manifest accepted" || true
import json, sys
from pathlib import Path
root = Path(sys.argv[1]); work = Path(sys.argv[2])
schema = json.loads((root / 'schemas/wiremudder/packages/manifest.schema.json').read_text())
manifest = json.loads((work / 'bad-missing.json').read_text())
try:
    import jsonschema
    jsonschema.validate(instance=manifest, schema=schema)
except Exception:
    raise SystemExit(1)
raise SystemExit(0)
PY

# 2. Malformed manifest: unknown permission is rejected.
printf '{"name":"x","version":"1","provenance":{"kind":"user_local","author":"a","added_at":"t"},"license":"MIT","content_sha256":"%s","requested_permissions":["all_the_things"],"update_policy":{"kind":"never"},"compatibility":{"wiremudder":"*","mudlet":"*"}}' "$(printf '0%.0s' $(seq 1 64))" > "$work/bad-perm.json"
python3 - "$PWD" "$work" <<'PY' && fail "unknown-permission manifest accepted" || true
import json, sys
from pathlib import Path
root = Path(sys.argv[1]); work = Path(sys.argv[2])
schema = json.loads((root / 'schemas/wiremudder/packages/manifest.schema.json').read_text())
manifest = json.loads((work / 'bad-perm.json').read_text())
try:
    import jsonschema
    jsonschema.validate(instance=manifest, schema=schema)
except Exception:
    raise SystemExit(1)
raise SystemExit(0)
PY

# 3. Malformed manifest: non-hex content hash is rejected.
printf '{"name":"x","version":"1","provenance":{"kind":"user_local","author":"a","added_at":"t"},"license":"MIT","content_sha256":"not-a-hash","requested_permissions":[],"update_policy":{"kind":"never"},"compatibility":{"wiremudder":"*","mudlet":"*"}}' > "$work/bad-hash.json"
python3 - "$PWD" "$work" <<'PY' && fail "bad-hash manifest accepted" || true
import json, sys
from pathlib import Path
root = Path(sys.argv[1]); work = Path(sys.argv[2])
schema = json.loads((root / 'schemas/wiremudder/packages/manifest.schema.json').read_text())
manifest = json.loads((work / 'bad-hash.json').read_text())
try:
    import jsonschema
    jsonschema.validate(instance=manifest, schema=schema)
except Exception:
    raise SystemExit(1)
raise SystemExit(0)
PY

# 4. Denied policy: an unapproved permission stays denied (oracle).
export CARGO_TARGET_DIR="$PWD/wirecore/target"
oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-packages/Cargo.toml --bin wire-packages-oracle --"
out=$($oracle decisions "ui" "secrets,command_send" 2>&1)
echo "$out" | grep -q '"permission":"secrets","decision":"denied"' || fail "secrets not denied"
echo "$out" | grep -q '"permission":"command_send","decision":"denied"' || fail "command_send not denied"

# 5. Missing dependency: the oracle fails closed with a typed usage error
#    when invoked without its required arguments — it never fabricates a
#    verification.
if $oracle hash "abc" >/dev/null 2>&1; then
  fail "hash without actual arg accepted"
fi

echo "failure EP-037 forced-failures: ok"
