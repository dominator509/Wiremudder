#!/usr/bin/env sh
# EP-029 M3 integration test: the bug-lab CLI drives the real
# wire-bug-automation crate through the full bounded remediation flow and
# the BLOCKED fallback, against real controlled state files.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

run() { # run <state> <args...>
  state="$1"; shift
  BUG_LAB_STATE="$state" CARGO_TARGET_DIR="$PWD/wirecore/target" \
    "$cargo_bin" run --quiet --manifest-path tools/wiremudder-bug-lab/Cargo.toml -- "$@"
}

st=$(mktemp /tmp/ep029_int_done_XXXX.json)
rm -f "$st"

# Full happy path: intake -> reproduce -> diagnose -> plan -> validate ->
# review -> canary -> done.
run "$st" intake lua P2 "lua panic on reconnect" >/dev/null
run "$st" reproduce >/dev/null
run "$st" diagnose "unchecked nil in reconnect" 90 >/dev/null
run "$st" plan "lua/reconnect.lua" "guard nil" "lua test" >/dev/null
run "$st" validate "3 tests passed, 0 failed" >/dev/null
run "$st" review reviewer-a yes "independent review; looks correct" >/dev/null
run "$st" canary "single profile" 60 "restore profile" >/dev/null
run "$st" done >/dev/null

grep -q '"stage": "done"' "$st" || fail "workflow did not reach done"
grep -q '"action": "complete"' "$st" || fail "completion not in audit trail"
rm -f "$st"

# BLOCKED fallback: reproduction evidence is missing -> block emits a
# complete report rather than proceeding.
st=$(mktemp /tmp/ep029_int_block_XXXX.json)
rm -f "$st"
run "$st" intake security P1 "provider credential exposure" >/dev/null
run "$st" reproduce >/dev/null
run "$st" diagnose "provider payload logged in clear" 85 >/dev/null
run "$st" plan "security/redactor.rs" "redact payload" "cargo test -p wire-bug-automation" >/dev/null
run "$st" validate "tests failed: redaction corpus regression" >/dev/null
run "$st" review reviewer-a no "independent review; regression found; security review required; performance impact reviewed" >/dev/null

grep -q '"stage": "blocked"' "$st" || fail "denied review did not reach blocked"
grep -q '"human_next_steps"' "$st" || fail "blocked report missing human_next_steps"
rm -f "$st"

echo "integration bug-lab-lifecycle: ok"
