#!/usr/bin/env sh
# EP-039 M2 unit test: the final release manifest declares canary/stable state
# honestly and never claims a signature the agent cannot produce.
set -eu
cd "$(dirname "$0")/../../../.."

final=release/wiremudder/final
[ -f "$final/manifest.json" ] || { echo "FAIL: final manifest missing" >&2; exit 1; }

python3 - "$final/manifest.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding='utf-8'))
assert m.get('schema_version') == 1, 'manifest schema_version'
assert m.get('channel') in {'canary', 'stable'}, f"channel {m.get('channel')}"
assert m.get('version'), 'version missing'
assert m.get('has_signature') is False, 'agent must never claim a signature'
assert m.get('has_checksums') is True, 'checksums required'
assert m.get('has_sbom') is True, 'sbom required'
assert m.get('has_provenance') is True, 'provenance required'
assert m.get('has_known_risks') is True, 'known risks required'
print('final manifest: ok')
PY
