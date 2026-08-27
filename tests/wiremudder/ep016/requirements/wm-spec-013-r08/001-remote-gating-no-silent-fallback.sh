#!/usr/bin/env sh
# WM-SPEC-013-R08: remote calls require the active privacy mode and
# explicit provider configuration; no silent remote fallback exists.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r08: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example integration_flow > /tmp/wm-r08.txt 2>&1 \
  || { cat /tmp/wm-r08.txt; fail "integration_flow"; }

grep -q "STATE denied: ok" /tmp/wm-r08.txt || fail "privacy gate denial"
grep -q "STATE degraded: ok" /tmp/wm-r08.txt || fail "explicit local fallback"
grep -q "STATE disabled-route: ok" /tmp/wm-r08.txt || fail "remote placeholder disabled"

# The shipped remote placeholder stays unconfigured and uncertified.
python3 - config/wiremudder/providers/routing-policy.example.json <<'PY' || fail "remote config state"
import json, sys
d = json.load(open(sys.argv[1]))
remote = [r for r in d["routes"] if r["kind"] == "remote"]
assert remote and remote[0]["configured"] is False
assert remote and remote[0]["certified"] is False
PY

echo "req WM-SPEC-013-R08: ok"
