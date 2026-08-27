#!/usr/bin/env sh
# EP-009 M3 integration test: run the real Lua 5.1 interpreter against the
# Lua compatibility corpus fixture and verify observed results match the
# reference trace (WM-SPEC-005-R06, WM-SPEC-008-R01).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

command -v lua5.1 >/dev/null || fail "lua5.1 not available"

FIXTURE=tests/wiremudder/classic/lua/001-corpus-string-table.json
[ -f "$FIXTURE" ] || fail "lua corpus fixture missing"

# Extract lua_eval payloads in seq order and evaluate each with real lua5.1
python3 - "$FIXTURE" <<'PY' || fail "lua corpus evaluation"
import json, subprocess, sys
fixture = json.load(open(sys.argv[1]))
expect = {}
for ev in fixture["reference_trace"]:
    if ev["kind"] == "lua_eval":
        # remember the next result event
        pass
results = {}
pending = None
for ev in fixture["reference_trace"]:
    if ev["kind"] == "lua_eval":
        code = ev["payload"]
        out = subprocess.run(["lua5.1", "-e", f"print(({code}))"],
                             capture_output=True, text=True, timeout=10)
        if out.returncode != 0:
            print(f"lua eval failed rc={out.returncode}: {code}: {out.stderr.strip()}")
            sys.exit(1)
        results[code] = out.stdout.strip()
    elif ev["kind"] == "lua_result":
        expected = ev["payload"]
        # find the most recent eval
        code = [e["payload"] for e in fixture["reference_trace"]
                if e["kind"] == "lua_eval" and e["seq"] < ev["seq"]][-1]
        got = results.get(code, "")
        if got != expected:
            print(f"lua mismatch: {code!r} expected {expected!r} got {got!r}")
            sys.exit(1)
print("integration: lua 5.1 corpus agrees with reference trace")
PY
