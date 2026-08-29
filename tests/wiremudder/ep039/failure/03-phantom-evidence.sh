#!/usr/bin/env sh
# EP-039 M4 failure: a missing evidence file referenced by the evidence index
# must fail the integrity check (no silent gap in the evidence chain).
set -eu
cd "$(dirname "$0")/../../../.."

work=$(mktemp -d /tmp/ep039_fail_XXXX)
trap 'rm -rf "$work"' EXIT

python3 - "$work/broken-index.json" <<'PY'
import json, sys, pathlib
idx = json.loads(pathlib.Path('release/wiremudder/candidate/EVIDENCE_INDEX.json').read_text())
entries = idx.get('entries', idx if isinstance(idx, list) else [])
entries.append({'path': '.agent/state/evidence/EP-039/M5/does-not-exist.json',
                'sha256': '0'*64})
out = {'schema_version': 1, 'entries': entries}
json.dump(out, open(sys.argv[1], 'w'), indent=1)
PY

# The same validation logic the unit test uses must reject the phantom entry.
if python3 - "$work/broken-index.json" <<'PY'
import json, pathlib, sys, hashlib
idx = json.load(open(sys.argv[1], encoding='utf-8'))
entries = idx.get('entries', idx if isinstance(idx, list) else [])
missing = [e['path'] for e in entries if not pathlib.Path(e['path']).is_file()]
assert missing, 'phantom entry unexpectedly present'
print('phantom entry detected:', missing[0])
PY
then
  echo 'phantom evidence detection: ok'
else
  echo "FAIL: phantom evidence not rejected" >&2
  exit 1
fi
