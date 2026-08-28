#!/usr/bin/env sh
# EP-034 M2 unit test: the update-fixtures tool generates ephemeral test
# signing keys and real signed manifests, and the wire-updater oracle drives
# the real core against them — signature verification, artifact hashing,
# admission policy (permission expansion, downgrade, lockdown, sessions),
# resume, health, and migration decisions.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"
oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"

work=$(mktemp -d /tmp/ep034_unit_XXXX)
trap 'rm -rf "$work"' EXIT

# 1. Generate an ephemeral test keypair and a real signed artifact+manifest.
echo "wiremudder-core-artifact-1.2.0" > "$work/core.bin"
$fixtures gen-key "$work" >/dev/null 2>&1 || fail "gen-key failed"
[ -f "$work/keypair.json" ] || fail "keypair.json missing"
pubkey=$(python3 -c "import json;print(json.load(open('$work/keypair.json'))['public_key_hex'])")
[ "${#pubkey}" -eq 64 ] || fail "public key not 64 hex"

$fixtures sign "$work/keypair.json" "$work/core.bin" core_app stable 1.2.0 \
  >/dev/null 2>&1 || fail "sign failed"
[ -f "$work/core.manifest.json" ] || fail "manifest missing"

# 2. Real signature verification: valid key verifies, wrong key denies.
out=$(mktemp "$work/out.XXXX")
$oracle verify-manifest "$pubkey" "$work/core.manifest.json" >"$out" 2>&1 \
  || { cat "$out" >&2; fail "verify-manifest failed"; }
grep -q "verified version=1.2.0" "$out" || fail "valid manifest not verified"

$oracle verify-manifest "$(python3 -c "print('ab'*32)")" "$work/core.manifest.json" >"$out" 2>&1 \
  || { cat "$out" >&2; fail "verify-manifest (wrong key) failed"; }
grep -q "denied:verification" "$out" || fail "wrong key not denied"

# 3. Artifact hash verification: good artifact ok, tampered artifact denied.
$oracle verify-artifact "$work/core.manifest.json" "$work/core.bin" >"$out" 2>&1 \
  || { cat "$out" >&2; fail "verify-artifact failed"; }
grep -q "artifact-ok" "$out" || fail "good artifact not verified"

echo "tampered-core-artifact" > "$work/core.bin.tampered"
$oracle verify-artifact "$work/core.manifest.json" "$work/core.bin.tampered" >"$out" 2>&1 \
  || { cat "$out" >&2; fail "verify-artifact (tampered) failed"; }
grep -q "artifact-denied:verification" "$out" || fail "tampered artifact not denied"

# 4. Admission policy against the real signed manifest.
$oracle admit "$work/core.manifest.json" none 1.0.0 0 0 0 >"$out" 2>&1
grep -q "admitted" "$out" || fail "valid upgrade not admitted"
$oracle admit "$work/core.manifest.json" none 2.0.0 0 0 0 >"$out" 2>&1
grep -q "denied:downgrade" "$out" || fail "downgrade not denied"
$oracle admit "$work/core.manifest.json" none 1.0.0 1 0 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "lockdown not deferred"
$oracle admit "$work/core.manifest.json" none 1.0.0 0 1 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "active sessions not deferred"

# 5. Permission-expanding manifest is denied (sign a manifest that requires
#    a permission the policy has not granted).
$fixtures sign "$work/keypair.json" "$work/core.bin" plugin_pack beta 1.3.0 \
  --permission network >/dev/null 2>&1 || fail "permission sign failed"
$oracle admit "$work/core.manifest.json" filesystem 1.0.0 0 0 0 >"$out" 2>&1
grep -q "denied:permission_expansion" "$out" || fail "permission expansion not denied"

# 6. Resume, health, migration, lanes, channels.
$oracle resume ab 10 4 3 >"$out" 2>&1
grep -q "resume-ok:7" "$out" || fail "resume not contiguous"
$oracle resume ab 10 4 9 >"$out" 2>&1
grep -q "resume-denied:validation" "$out" || fail "resume overflow not denied"

$oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "crash loop not quarantined"
$oracle health 0,0,1 >"$out" 2>&1
grep -q "healthy" "$out" || fail "clean startup not healthy"

$oracle migration 1 2 >"$out" 2>&1
grep -q "backup_required from=1 to=2" "$out" || fail "migration backup not planned"

$oracle lanes >"$out" 2>&1
grep -q "lane core_app optional=false" "$out" || fail "core lane wrong"
grep -q "lane audio_pack optional=true" "$out" || fail "optional lane wrong"
$oracle channels >"$out" 2>&1
grep -q "channel stable" "$out" || fail "channel list wrong"

echo "unit EP-034 update-fixtures-and-oracle: ok"
