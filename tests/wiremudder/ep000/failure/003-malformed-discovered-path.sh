#!/usr/bin/env sh
# Failure test: malformed discovered-path amendments must be rejected.
set -eu
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cp .agent/expected-files/EP-000.discovered.txt "$tmp"
printf 'not-json\n' >> .agent/expected-files/EP-000.discovered.txt
set +e
sh scripts/discovered-path-check.sh EP-000 >/tmp/wm-fail-003.out 2>&1
rc=$?
set -e
cp "$tmp" .agent/expected-files/EP-000.discovered.txt
[ "$rc" -ne 0 ] || { echo "FAIL: malformed discovered path accepted" >&2; exit 1; }
grep -q "discovered path check EP-000: FAIL" /tmp/wm-fail-003.out || { echo "FAIL: expected FAIL diagnostic missing" >&2; exit 1; }
echo "failure malformed-discovered-path: ok"
