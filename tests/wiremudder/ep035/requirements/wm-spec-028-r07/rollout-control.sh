#!/usr/bin/env sh
# WM-SPEC-028-R07 (live-fire): post-release monitoring uses opt-in health
# signals and maintainer review and can pause rollout or revoke an update
# manifest.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"

tmp=$(mktemp -d /tmp/ep035_r07_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

# 1. Rollout control can pause and revoke an update manifest.
$oracle revoke wm-1.0.0 >"$out" 2>&1
grep -q '"manifest_revoked":true' "$out" || fail "manifest not revocable"
grep -q '"rollout_paused":true' "$out" || fail "rollout not pausable"

# 2. Revocation is a maintainer decision with a note.
grep -q '"note":' "$out" || fail "revocation missing rationale"

# 3. Monitoring uses opt-in health signals: the release core is local and
#    never requires hosted telemetry (SPEC-026-R08).
grep -q "opt-in" docs/wiremudder/release/operations/runbook.md \
  || fail "runbook missing opt-in monitoring"

# 4. The release pipeline never auto-deploys.
grep -q "WIREMUDDER_AUTO_DEPLOY=false" .env || fail "auto-deploy not false"

echo "req WM-SPEC-028-R07: ok"
