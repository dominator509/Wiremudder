#!/usr/bin/env sh
# Security test: no secret material may appear in build configure logs.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"
[ -f "$builddir/CMakeCache.txt" ] || { echo "SKIP: no cache yet" >&2; exit 0; }
python3 - "$builddir/CMakeCache.txt" <<'PY' || { echo "FAIL: secret scan" >&2; exit 1; }
import re, sys
text = open(sys.argv[1], encoding='utf-8', errors='replace').read()
patterns = [
    re.compile(r'(?i)(api[_-]?key|secret|password|token|private[_-]?key)\s*[:=]\s*\S+'),
    re.compile(r'-----BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY-----'),
    re.compile(r'\bAKIA[0-9A-Z]{16}\b'),
]
for pat in patterns:
    assert not pat.search(text), f'possible secret in cache: {pat.pattern}'
print('security configure-cache-no-secrets: ok')
PY
echo "security configure-cache-no-secrets: ok"
