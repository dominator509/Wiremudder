# WM-SPEC-013-R06: slow/failed/unavailable/budget-exceeded providers
# degrade to smaller local route or user-visible no-suggestion; gameplay
# never waits.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-013-r06: FAIL - $1" >&2; exit 1; }
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example failure_matrix > /tmp/wm-r06.txt 2>/dev/null || fail "failure matrix"
grep -q "unavailable:ok" /tmp/wm-r06.txt || fail "unavailable degrade"
grep -q "timeout:ok" /tmp/wm-r06.txt || fail "timeout degrade"
grep -q "budget-exceeded:ok" /tmp/wm-r06.txt || fail "budget degrade"
rm -f /tmp/wm-r06.txt
echo "wm-spec-013-r06: ok"
