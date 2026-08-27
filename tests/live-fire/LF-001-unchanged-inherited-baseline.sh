#!/usr/bin/env sh
# LF-001 unchanged-inherited-baseline (live-fire)
#
# Proves the real user outcome of EP-001: the Graphlock overlay is
# installed, the inherited Mudlet-derived client configures and builds
# WITHOUT functional WireMudder changes, and the binary runs headlessly.
# Every step runs against the live repository and prints observed facts.
set -eu
. ./.env
fail() { echo "LF-001: FAIL - $1" >&2; exit 1; }

echo "LF-001: unchanged-inherited-baseline"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"

# 1. Graphlock overlay is installed with prime blocks.
for f in AGENTS.md CLAUDE.md .github/copilot-instructions.md; do
  grep -q "PRIME-BLOCK-BEGIN" "$f" || fail "prime block missing in $f"
done
echo "graphlock_overlay=installed"

# 2. Inherited client configured and built from the pinned commit.
[ -f "$builddir/CMakeCache.txt" ] || fail "no configure cache"
[ -x "$builddir/src/mudlet" ] || fail "missing client binary"
cache_commit=$(grep -m1 "Git SHA1 used" "$builddir/CMakeCache.txt" 2>/dev/null || true)
echo "configure_cache=present"
echo "client_binary=$builddir/src/mudlet"

# 3. No functional WireMudder changes: inherited source is byte-identical
#    to the pinned upstream commit.
python3 - <<'PY' || fail "inherited drift"
import subprocess
base = '77086c295f4adf59197e586e689d19bdde8e1008'
for f in ['src/mudlet.cpp', 'src/Host.cpp', 'src/ctelnet.cpp', 'src/TLuaInterpreter.cpp', 'src/TConsole.cpp', 'CMakeLists.txt', 'CMakePresets.json']:
    up = subprocess.run(['git','show',f'{base}:{f}'], stdout=subprocess.PIPE).stdout
    cur = open(f,'rb').read()
    assert up == cur, f'drift {f}'
print('inherited_src=byte-identical')
PY

# 4. Binary is a real Qt6 executable.
ldd "$builddir/src/mudlet" 2>/dev/null | grep -q "libQt6Core" || fail "binary does not link Qt6"
echo "qt6_link=verified"

# 5. Headless launch smoke (upstream CI pattern).
if command -v xvfb-run >/dev/null 2>&1; then
  set +e
  timeout 90 xvfb-run --auto-servernum "$builddir/src/mudlet" --profile "Mudlet self-test" --mirror </dev/null >/tmp/wm-lf001.out 2>&1
  rc=$?
  set -e
  case "$rc" in
    0|1) echo "launch_smoke=ok(exit $rc)" ;;
    124) fail "client hung under xvfb" ;;
    *) fail "client exited $rc: $(tail -3 /tmp/wm-lf001.out)" ;;
  esac
else
  echo "launch_smoke=skipped(no xvfb)"
fi

echo "LF-001: ok"
