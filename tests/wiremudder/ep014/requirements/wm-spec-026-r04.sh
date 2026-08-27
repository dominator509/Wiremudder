#!/usr/bin/env sh
# WM-SPEC-026-R04: metrics cover storage delay and queue depth.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "wm-spec-026-r04: FAIL - $1" >&2; exit 1; }

# The M4 performance fixture emits real latency evidence: append
# throughput per line and FTS query latency per query, against budgets.
EV=.agent/state/evidence/EP-014/M4/performance-001.json
[ -f "$EV" ] || fail "perf evidence missing"
grep -q '"append_per_line_ms"' "$EV" || fail "append metric missing"
grep -q '"search_per_query_ms"' "$EV" || fail "search metric missing"
grep -q '"budgets_ms"' "$EV" || fail "budgets missing"
grep -q '"ok": true' "$EV" || fail "perf not ok"

# Queue depth is an observable contract: bounded queue with typed
# exhaustion, covered by the failure matrix.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml \
  --example failure_matrix > /tmp/wm-r26-failure.txt 2>/dev/null \
  || fail "failure matrix"
grep -q "queue-full:ok" /tmp/wm-r26-failure.txt || fail "queue metric"
rm -f /tmp/wm-r26-failure.txt

echo "wm-spec-026-r04: ok"
