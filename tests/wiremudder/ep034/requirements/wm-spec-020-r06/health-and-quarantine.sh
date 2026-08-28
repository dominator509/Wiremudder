#!/usr/bin/env sh
# WM-SPEC-020-R06 (live-fire): an update is healthy only after clean startup
# and required smoke checks; crash loops trigger local quarantine and
# rollback guidance.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"

tmp=$(mktemp -d /tmp/ep034_r06_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

# Healthy only after clean startup and smoke checks.
$oracle health 1 >"$out" 2>&1
grep -q "healthy" "$out" || fail "clean startup not healthy"
$oracle health 0,0,1 >"$out" 2>&1
grep -q "healthy" "$out" || fail "recovery after failures not healthy"

# Crash loops trigger local quarantine and rollback guidance.
$oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "crash loop not quarantined"

# The runbook documents the quarantine/rollback guidance.
grep -q "quarantin" docs/wiremudder/updater/operations/runbook.md \
  || fail "runbook missing quarantine guidance"
grep -q "rollback" docs/wiremudder/updater/operations/runbook.md \
  || fail "runbook missing rollback guidance"

echo "req WM-SPEC-020-R06: ok"
