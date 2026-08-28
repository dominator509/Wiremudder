#!/usr/bin/env sh
# EP-028 M3 e2e test: the real user-visible telemetry/replay/diagnostics
# flow must run through the production wire-telemetry and wire-replay
# crates and prove every acceptance obligation from the node contract.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep028_e2e_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet \
  --manifest-path wirecore/crates/wire-replay/Cargo.toml \
  --example e2e_diagnostics >"$out" 2>&1 || {
  cat "$out" >&2
  fail "diagnostics e2e did not run"
}

grep -q "Telemetry is off by default externally" "$out" || fail "obligation 1 (off by default) not proven"
grep -q "Ring buffers stay bounded at capacity" "$out" || fail "obligation 2 (bounded ring) not proven"
grep -q "Redaction corpus strips secrets before capture" "$out" || fail "obligation 3 (redaction) not proven"
grep -q "Replay is deterministic" "$out" || fail "obligation 4 (deterministic replay) not proven"
grep -q "Bundle preview matches exported content" "$out" || fail "obligation 5 (preview/export) not proven"
grep -q "No secret or private data leaks into fixtures" "$out" || fail "obligation 6 (no leaks) not proven"
grep -q "e2e EP-028 diagnostics-flow: ok" "$out" || fail "e2e did not complete"

echo "e2e EP-028 diagnostics-flow: ok"
