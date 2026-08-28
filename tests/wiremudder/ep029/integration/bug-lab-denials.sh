#!/usr/bin/env sh
# EP-029 M3 integration test: denial and error states are real and
# fail-closed — no reproduction means no diagnosis, a patch outside the
# owning subsystem is refused, and a non-independent review is refused.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

run() { # run <state> <args...>
  state="$1"; shift
  BUG_LAB_STATE="$state" CARGO_TARGET_DIR="$PWD/wirecore/target" \
    "$cargo_bin" run --quiet --manifest-path tools/wiremudder-bug-lab/Cargo.toml -- "$@" 2>&1 || true
}

st=$(mktemp /tmp/ep029_int_deny_XXXX.json)
rm -f "$st"

# Denied: diagnosis without reproduction.
out=$(run "$st" intake network P3 "packet drop on reconnect")
out=$(run "$st" diagnose "guessed" 50)
echo "$out" | grep -q "diagnosis requires a prior reproduction" \
  || fail "diagnosis without reproduction was not denied"

# Denied: patch plan outside owning subsystem.
run "$st" reproduce >/dev/null
run "$st" diagnose "routing bug" 80 >/dev/null
out=$(run "$st" plan "src/wiremudder/ui/remote.lua" "escape" "t")
echo "$out" | grep -q "patch plan touches paths outside the owning subsystem" \
  || fail "cross-subsystem patch was not denied"

# Denied: independent review requires a different reviewer id.
run "$st" plan "network/router.lua" "fix routing" "t" >/dev/null
run "$st" validate "1 passed" >/dev/null
out=$(run "$st" review planner-network yes "self review")
echo "$out" | grep -q "reviewer must differ from the planner" \
  || fail "self-review was not denied"

rm -f "$st"
echo "integration bug-lab-denials: ok"
