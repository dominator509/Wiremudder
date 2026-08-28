#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-028-R03 — known critical defects,
# security findings, P0/P1 regressions, data-loss risks, secret leakage,
# signature failures, or emergency-stop failures block release.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

out=$(mktemp /tmp/ep033_r0283_XXXX.log)
findings=$(mktemp /tmp/ep033_r0283_findings_XXXX.json)
trap 'rm -f "$out" "$findings"' EXIT

# A critical security finding blocks release fail-closed.
printf '[{"category":"security","detail":"secret leaked in diagnostics"}]' > "$findings"
if "$cargo_bin" run --quiet --release --manifest-path security/wiremudder/Cargo.toml -- \
  release-block "$findings" >"$out" 2>&1; then
  cat "$out" >&2
  fail "critical finding did not block release"
fi
grep -q "blocked=true" "$out" || fail "blocked sentinel missing"

echo "requirement WM-SPEC-028-R03: ok"
