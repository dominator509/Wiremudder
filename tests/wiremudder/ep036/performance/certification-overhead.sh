#!/usr/bin/env sh
# EP-036 M4 performance test: certification/chaos overhead stays within the
# SPEC-004 P4 budget (1 ms). Measures the updater hot path and the release
# artifact-dir check on this host, using the real measured fixtures.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

# 1. Updater hot path (real measured distribution).
out=$(mktemp /tmp/ep036_perf_u_XXXX.log)
"$cargo_bin" run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml \
  --example perf_fixture >"$out" 2>&1 || { cat "$out" >&2; fail "updater perf failed"; }
grep -q "^perf updater:" "$out" || fail "updater perf sentinel missing"

# 2. Release artifact-dir check (real measured distribution).
out2=$(mktemp /tmp/ep036_perf_r_XXXX.log)
"$cargo_bin" run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml \
  --example perf_fixture >"$out2" 2>&1 || { cat "$out2" >&2; fail "release perf failed"; }
grep -q "^perf release:" "$out2" || fail "release perf sentinel missing"

python3 - "$out" "$out2" <<'PY' || fail "perf budget check failed"
import re, sys
for path, name in [(sys.argv[1], "updater"), (sys.argv[2], "release")]:
    text = open(path).read()
    m = re.search(rf"perf {name}: p50_us=(\d+) p95_us=(\d+) max_us=(\d+) budget_us=(\d+)", text)
    assert m, f"{name} perf line missing"
    p50, p95, mx, budget = map(int, m.groups())
    assert p95 <= budget, f"{name} p95 {p95}us over budget {budget}us"
    assert mx <= budget, f"{name} max {mx}us over budget {budget}us"
    print(f"perf {name}: p50={p50}us p95={p95}us max={mx}us budget={budget}us OK")
PY

echo "performance EP-036 certification-overhead: ok"
