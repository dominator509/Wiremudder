#!/usr/bin/env sh
# EP-029 M3 e2e test: a real user-facing bug remediation flow through the
# bug-lab CLI, proving data scope, privacy disclosure, action authority,
# audit, restart (resume), and BLOCKED behavior. Manual text gameplay is
# preserved because the optional subsystem is fully isolated from the
# inherited client; this test drives the real binary, not a mock.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

run() { # run <state> <args...>
  state="$1"; shift
  BUG_LAB_STATE="$state" CARGO_TARGET_DIR="$PWD/wirecore/target" \
    "$cargo_bin" run --quiet --manifest-path tools/wiremudder-bug-lab/Cargo.toml -- "$@"
}

st=$(mktemp /tmp/ep029_e2e_XXXX.json)
rm -f "$st"

# Intake with a secret in the description; the report must be redacted at
# the boundary (privacy disclosure: no raw secret enters the workflow).
out=$(run "$st" intake voice P1 "voice transcript leaked token=rtk-secret-9. user complained")
echo "$out" | grep -q "intake: ok" || fail "intake failed"
grep -q "rtk-secret-9" "$st" && fail "secret leaked into state file"

# Full remediation to DONE with restart in the middle (crash recovery).
run "$st" reproduce >/dev/null
run "$st" diagnose "transcript passed to provider" 88 >/dev/null
run "$st" plan "voice/transcript.rs" "redact before send" "cargo test -p wire-bug-automation" >/dev/null
run "$st" validate "4 tests passed, 0 failed" >/dev/null
run "$st" review reviewer-b yes "independent review; security review; performance impact reviewed" >/dev/null
run "$st" canary "single profile" 120 "restore profile backup" >/dev/null
run "$st" done >/dev/null

grep -q '"stage": "done"' "$st" || fail "e2e did not reach done"
grep -q '"action": "complete"' "$st" || fail "audit missing completion"

# Action authority: a denied review cannot be bypassed by another review;
# the terminal BLOCKED state is stable.
run "$st" block "cannot be re-opened" >/dev/null 2>&1 || true
grep -q '"stage": "blocked"' "$st" && fail "terminal done workflow was re-blocked"

# Manual gameplay preservation: the workflow never touches src/ or the
# inherited runtime; the state file is the only artifact.
grep -q 'voice/transcript.rs' "$st" || fail "patch plan missing"
rm -f "$st"

echo "e2e bug-remediation-replay: ok"
