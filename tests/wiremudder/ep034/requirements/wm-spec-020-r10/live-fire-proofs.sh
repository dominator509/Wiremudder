#!/usr/bin/env sh
# WM-SPEC-020-R10 (live-fire): release, migration, rollback, channel
# switching, permission expansion, signature failure, and active-session
# deferral receive live-fire proofs.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"
oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"

tmp=$(mktemp -d /tmp/ep034_r10_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

$fixtures gen-key "$tmp" >/dev/null 2>&1 || fail "gen-key failed"
pubkey=$(python3 -c "import json;print(json.load(open('$tmp/keypair.json'))['public_key_hex'])")
echo "artifact" > "$tmp/core.bin"

# Release: a signed stable release verifies and is admitted.
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app stable 2.0.0 >/dev/null 2>&1
$oracle verify-manifest "$pubkey" "$tmp/core.manifest.json" >"$out" 2>&1
grep -q "verified version=2.0.0" "$out" || fail "release not verified"
$oracle admit "$tmp/core.manifest.json" none 1.0.0 0 0 0 >"$out" 2>&1
grep -q "admitted" "$out" || fail "release not admitted"

# Channel switching: all four channels are real and parse.
$oracle channels >"$out" 2>&1
for c in development canary beta stable; do
  grep -q "channel $c" "$out" || fail "channel $c missing"
done

# Migration: backup required before install, restore on rollback.
$oracle migration 1 2 >"$out" 2>&1
grep -q "backup_required" "$out" || fail "migration backup not proven"
$oracle migration 2 1 >"$out" 2>&1
grep -q "restore_required" "$out" || fail "migration restore not proven"

# Rollback: crash loop triggers quarantine and rollback guidance.
$oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "rollback trigger not proven"

# Permission expansion: denied live.
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" plugin_pack beta 2.1.0 \
  --permission ai_egress >/dev/null 2>&1
$oracle admit "$tmp/core.manifest.json" filesystem 1.0.0 0 0 0 >"$out" 2>&1
grep -q "denied:permission_expansion" "$out" || fail "permission expansion not denied"

# Signature failure: wrong key denied live.
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app stable 2.2.0 >/dev/null 2>&1
$oracle verify-manifest "$(python3 -c "print('cd'*32)")" "$tmp/core.manifest.json" >"$out" 2>&1
grep -q "denied:verification" "$out" || fail "signature failure not denied"

# Active-session deferral: deferred live.
$oracle admit "$tmp/core.manifest.json" none 1.0.0 0 1 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "active-session deferral not proven"

echo "req WM-SPEC-020-R10: ok"
