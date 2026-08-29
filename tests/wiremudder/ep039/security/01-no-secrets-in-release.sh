#!/usr/bin/env sh
# EP-039 M4 security: no signing keys or secrets anywhere in the release
# boundaries, and the manifest/provenance never exposes key material.
set -eu
cd "$(dirname "$0")/../../../.."

for d in release/wiremudder/final release/wiremudder/candidate; do
  if find "$d" -type f | grep -qiE '\.(pem|key|p12|pfx|p8|pgp)$|(^|/)secret|\.env$'; then
    echo "FAIL: secret-looking file in $d" >&2
    find "$d" -type f | grep -qiE '\.(pem|key|p12|pfx|p8|pgp)$|(^|/)secret|\.env$' | head -3 >&2
    exit 1
  fi
done

python3 - <<'PY'
import json, pathlib, re
for name in ('release/wiremudder/final/manifest.json',
             'release/wiremudder/final/provenance.json',
             'release/wiremudder/candidate/provenance.json'):
    text = pathlib.Path(name).read_text()
    json.loads(text)  # must parse
    assert 'BEGIN' not in text, f"key material in {name}"
    assert 'PRIVATE KEY' not in text, f"private key text in {name}"
print('release boundary secret scan: ok')
PY
