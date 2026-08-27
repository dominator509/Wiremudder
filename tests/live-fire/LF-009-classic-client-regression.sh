#!/usr/bin/env sh
# LF-009 classic-client-regression (live-fire)
#
# Proves the real user outcome of EP-009: the inherited classic-client
# surface is preserved and parity is verified against observable traces.
# Real controlled dependencies only - the actual lua5.1 interpreter and
# the baseline mudlet binary. No mocks, no stubs, no sample success.
set -eu
fail() { echo "LF-009: FAIL - $1" >&2; exit 1; }

cd "$(dirname "$0")/../.."
ORACLE="python3 compatibility/classic/parity_oracle.py"

echo "LF-009: classic-client-regression"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. Real Lua 5.1 interpreter agrees with the compatibility corpus
#    (WM-SPEC-005-R06 Lua 5.1 is a contract, WM-SPEC-008-R01 primary
#    scripting surface).
command -v lua5.1 >/dev/null || fail "lua5.1 not available"
sh tests/wiremudder/ep009/integration/001-lua-corpus-live.sh >/dev/null 2>&1 \
  || fail "Lua 5.1 corpus divergence"

# 2. Baseline mudlet binary present and loadable (WM-SPEC-005-R01).
BIN=build-linux-debug-nosan/src/mudlet
[ -f "$BIN" ] && [ -x "$BIN" ] || fail "mudlet baseline binary missing"
file "$BIN" | grep -q "ELF 64-bit" || fail "mudlet not ELF64"
ldd "$BIN" 2>/dev/null | grep -q "Qt6Core" || fail "mudlet does not link Qt6Core"

# 3. Full fixture corpus agrees through the oracle
#    (WM-SPEC-005-R10 no parity claim from compilation alone).
CORPUS=$($ORACLE --compare-all tests/wiremudder/classic)
echo "$CORPUS" | grep -q "all .* fixtures agree" || fail "corpus disagreement"

# 4. Manual gameplay preserved under optional degradation
#    (WM-SPEC-007-R08 explicit degraded state).
sh tests/wiremudder/ep009/e2e/001-parity-flow.sh >/dev/null 2>&1 \
  || fail "manual gameplay preservation"

# 5. Automation order compatibility: alias/trigger/timer/macro traces
#    preserve inherited ordering (WM-SPEC-005-R03, SPEC-008).
python3 - <<'PY' || fail "automation order trace"
import json, glob
order_ok = True
for f in glob.glob("tests/wiremudder/classic/automation/*.json"):
    fx = json.load(open(f))
    ref = [e["kind"] for e in fx["reference_trace"]]
    wm = [e["kind"] for e in fx["wiremudder_trace"]]
    if fx["level"] == "subset":
        i = 0
        for k in ref:
            while i < len(wm) and wm[i] != k:
                i += 1
            if i >= len(wm):
                order_ok = False
                print(f"order lost: {f}: {k} missing")
                break
            i += 1
    elif ref != wm:
        order_ok = False
        print(f"order changed: {f}")
if not order_ok:
    raise SystemExit(1)
print("automation order compatible")
PY

# 6. Feature coverage and spec trace gates
sh scripts/feature-coverage-check.sh >/dev/null 2>&1 || fail "feature coverage"
sh scripts/spec-trace-check.sh >/dev/null 2>&1 || fail "spec trace"

echo "LF-009: ok"
