#!/usr/bin/env sh
# EP-039 M4 failure: no fabricated signing claim can survive the release
# gates. The manifest completeness flag is only a bookkeeping flag; the real
# signature boundary is the artifact gate (dir-check require-sig=1), which
# demands a physical wiremudder.sig. A JSON lie cannot manufacture one.
set -eu
cd "$(dirname "$0")/../../../.."

oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || { echo "SKIP: oracle binary not built (run packaging build first)" >&2; exit 0; }

work=$(mktemp -d /tmp/ep039_fail_XXXX)
trap 'rm -rf "$work"' EXIT

# 1. The honest manifest is refused for stable: no signature recorded.
if "$oracle" stable-check release/wiremudder/final/manifest.json 2>&1 \
     | grep -q 'stable-incomplete.*signature'; then
  echo 'honest unsigned manifest refused: ok'
else
  echo "FAIL: honest unsigned manifest was not refused for stable" >&2
  exit 1
fi

# 2. Take the honest final manifest and lie about a signature. The manifest
#    completeness check is a flag check by design (SPEC-028-R05); the lie is
#    defeated by the PHYSICAL artifact gate, not by the manifest flag.
python3 - release/wiremudder/final/manifest.json "$work/lie.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding='utf-8'))
m['has_signature'] = True
m['signature'] = 'fabricated-by-test'
json.dump(m, open(sys.argv[2], 'w'), indent=1)
PY

if "$oracle" dir-check release/wiremudder/final 1 2>&1 \
     | grep -q 'dir-incomplete.*wiremudder.sig'; then
  echo 'signature lie rejection: ok (artifact gate requires physical wiremudder.sig)'
else
  echo "FAIL: artifact gate did not refuse the unsigned release directory" >&2
  exit 1
fi

# 3. No signature material exists anywhere in the release boundary, so no
#    physical signature can be claimed.
if find release/wiremudder -name '*.sig' -o -name '*.asc' -o -name '*.gpg' 2>/dev/null | grep -q .; then
  echo "FAIL: signature material present in release boundary" >&2
  exit 1
fi
echo 'no signature material in release boundary: ok'
