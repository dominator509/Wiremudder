#!/usr/bin/env sh
# Security test: build outputs stay within the build directory; no build
# artifact may appear in the source tree.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"
[ -d "$builddir" ] || { echo "SKIP: no build dir yet" >&2; exit 0; }
python3 - "$builddir" <<'PY' || { echo "FAIL: build artifact leak" >&2; exit 1; }
import subprocess, sys
build = sys.argv[1]
# Any untracked file in the source tree that is not in the build dir or
# an authorized test/state path is a leak.
out = subprocess.run(['git','status','--porcelain','--untracked-files=all'], text=True, stdout=subprocess.PIPE).stdout
leaks = []
for line in out.splitlines():
    if not line.startswith('?? '):
        continue
    p = line[3:]
    if p.startswith(build + '/') or p.startswith('.agent/') or p.startswith('tests/wiremudder/') or p.startswith('docs/wiremudder/') or p.startswith('scripts/node-verifiers/'):
        continue
    leaks.append(p)
assert not leaks, f'build artifacts leaked: {leaks}'
print('security no-build-artifact-leak: ok')
PY
echo "security no-build-artifact-leak: ok"
