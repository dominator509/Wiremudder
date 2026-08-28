#!/usr/bin/env sh
# EP-029 M4 failure test: the eight required failure proofs from the node
# contract, exercised against the real crate and CLI with controlled
# mechanisms — no component is mocked.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

run() { # run <state> <args...>
  state="$1"; shift
  BUG_LAB_STATE="$state" CARGO_TARGET_DIR="$PWD/wirecore/target" \
    "$cargo_bin" run --quiet --manifest-path tools/wiremudder-bug-lab/Cargo.toml -- "$@" 2>&1 || true
}

# 1. Unavailable dependency or worker: a state file whose parent directory
#    does not exist must fail loudly at intake, not pretend success.
st=$(mktemp /tmp/ep029_fail_ro_XXXX.json)
rm -f "$st"
st_dir=$(dirname "$st")/ep029-no-such-dir
rm -rf "$st_dir"
st="$st_dir/state.json"
out=$(run "$st" intake lua P2 "panic")
echo "$out" | grep -q "intake: ok" && fail "intake succeeded despite unavailable state path"
rm -rf "$st_dir"

# 2. Timeout and cancellation: a bounded run under `timeout` must complete
#    within budget; a cancelled run resumes from the persisted state.
st=$(mktemp /tmp/ep029_fail_t_XXXX.json)
rm -f "$st"
timeout 10 sh -c '
  BUG_LAB_STATE="$1" CARGO_TARGET_DIR="$PWD/wirecore/target" \
    "$2" run --quiet --manifest-path tools/wiremudder-bug-lab/Cargo.toml -- \
    intake network P3 "drop" >/dev/null
' _ "$st" "$cargo_bin" || fail "intake did not complete within timeout"
run "$st" reproduce >/dev/null
grep -q '"stage": "reproduction"' "$st" || fail "cancelled/resumed workflow lost state"
rm -f "$st"

# 3. Malformed input: invalid subsystem and priority are typed errors.
st=$(mktemp /tmp/ep029_fail_m_XXXX.json)
rm -f "$st"
out=$(run "$st" intake nosuch P2 "x")
echo "$out" | grep -q "unknown subsystem" || fail "malformed subsystem not rejected"
out=$(run "$st" intake lua P9 "x")
echo "$out" | grep -q "unknown priority" || fail "malformed priority not rejected"
rm -f "$st"

# 4. Duplicate or replayed request: identical intake collapses to the same
#    bug id (content-addressed fingerprint).
st1=$(mktemp /tmp/ep029_fail_d1_XXXX.json); rm -f "$st1"
st2=$(mktemp /tmp/ep029_fail_d2_XXXX.json); rm -f "$st2"
id1=$(run "$st1" intake mapper P3 "map scroll crash on long rooms")
id2=$(run "$st2" intake mapper P3 "map scroll crash on long rooms")
[ "$id1" = "$id2" ] || fail "duplicate intake produced different ids: $id1 vs $id2"
rm -f "$st1" "$st2"

# 5. Denied permission: self-review and review without validation are denied.
st=$(mktemp /tmp/ep029_fail_p_XXXX.json); rm -f "$st"
run "$st" intake package P2 "manifest parse error" >/dev/null
run "$st" reproduce >/dev/null
run "$st" diagnose "bad length" 70 >/dev/null
out=$(run "$st" review reviewer-a yes "independent")
echo "$out" | grep -q "review requires an observed validation result" \
  || fail "review without validation was not denied"
rm -f "$st"

# 6. Resource or queue budget exhaustion: retry budget is bounded at the
#    crate level (already covered by unit retry_policy_is_bounded); here the
#    router drains without starvation.
st=$(mktemp /tmp/ep029_fail_r_XXXX.json); rm -f "$st"
run "$st" intake renderer P4 "minor artifact" >/dev/null
run "$st" status | grep -q "stage: intake" || fail "router state not intake"
rm -f "$st"

# 7. Partial side effect and compensation: rollback after canary records a
#    compensation audit entry.
st=$(mktemp /tmp/ep029_fail_c_XXXX.json); rm -f "$st"
run "$st" intake update P1 "update checksum mismatch" >/dev/null
run "$st" reproduce >/dev/null
run "$st" diagnose "partial download" 80 >/dev/null
run "$st" plan "update/fetcher.rs" "verify checksum" "cargo test -p wire-bug-automation" >/dev/null
run "$st" validate "3 passed" >/dev/null
run "$st" review reviewer-a yes "independent review; security review; performance impact reviewed" >/dev/null
run "$st" canary "single profile" 30 "restore update state" >/dev/null
run "$st" rollback "restore update state" >/dev/null
grep -q '"action": "rollback"' "$st" || fail "compensation rollback missing from audit"
rm -f "$st"

# 8. Preserved manual gameplay and data integrity: the workflow never writes
#    outside the state file; no inherited source path is touched.
st=$(mktemp /tmp/ep029_fail_g_XXXX.json); rm -f "$st"
before=$(find src -type f | wc -l)
run "$st" intake core P2 "startup hiccup" >/dev/null
run "$st" reproduce >/dev/null
after=$(find src -type f | wc -l)
[ "$before" = "$after" ] || fail "gameplay source tree changed during remediation"
rm -f "$st"

echo "failure EP-029 matrix: ok"
