#!/usr/bin/env sh
# EP-034 M4 failure test: forced failures fail closed (SPEC-025, SPEC-022).
#
# Real controlled failure mechanisms against the real core: malformed JSON,
# oversized input, wrong key, unsigned manifest, missing artifact, tampered
# artifact, invalid hex, resume gaps, and crash loops. Each must produce a
# typed denial or error — never a false success.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"
oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"

tmp=$(mktemp -d /tmp/ep034_fail_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

# 1. Malformed manifest JSON fails closed (typed denial, never verified).
echo '{ not json' > "$tmp/bad.json"
$oracle verify-manifest "$(python3 -c "print('ab'*32)")" "$tmp/bad.json" >"$out" 2>&1 \
  || true
grep -q "denied:verification" "$out" || fail "malformed manifest not denied"

# 2. Oversized manifest fails closed (resource exhaustion).
python3 -c "print('x'*300000)" > "$tmp/huge.json"
$oracle verify-manifest "$(python3 -c "print('ab'*32)")" "$tmp/huge.json" >"$out" 2>&1 \
  || true
grep -q "denied:resource_exhaustion" "$out" || fail "oversized manifest not denied"

# 3. Unsigned manifest is denied (SPEC-020-R04).
$fixtures gen-key "$tmp" >/dev/null 2>&1 || fail "gen-key failed"
pubkey=$(python3 -c "import json;print(json.load(open('$tmp/keypair.json'))['public_key_hex'])")
echo "core-artifact" > "$tmp/core.bin"
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app stable 1.0.0 >/dev/null 2>&1 || fail "sign failed"
python3 - <<PY
import json
p = '$tmp/core.manifest.json'
m = json.load(open(p))
m['signature'] = ''
json.dump(m, open(p, 'w'))
PY
$oracle verify-manifest "$pubkey" "$tmp/core.manifest.json" >"$out" 2>&1
grep -q "denied:verification" "$out" || fail "unsigned manifest not denied"

# 4. Wrong key denied.
$oracle verify-manifest "$(python3 -c "print('cd'*32)")" "$tmp/core.manifest.json" >"$out" 2>&1
grep -q "denied:verification" "$out" || fail "wrong-key manifest not denied"

# 5. Tampered artifact denied (corrupted download).
echo "tampered" > "$tmp/bad.bin"
$oracle verify-artifact "$tmp/core.manifest.json" "$tmp/bad.bin" >"$out" 2>&1
grep -q "artifact-denied:verification" "$out" || fail "tampered artifact not denied"

# 6. Missing artifact fails closed (oracle error, nonzero exit).
if $oracle verify-artifact "$tmp/core.manifest.json" "$tmp/nonexistent.bin" >"$out" 2>&1; then
  cat "$out" >&2; fail "missing artifact accepted"
fi

# 7. Invalid public key hex fails closed (nonzero exit, typed error).
if $oracle verify-manifest "zz" "$tmp/core.manifest.json" >"$out" 2>&1; then
  cat "$out" >&2; fail "invalid key hex accepted"
fi

# 8. Resume offset gap is rejected (interrupted download cannot skip).
$oracle resume ab 10 4 9 >"$out" 2>&1
grep -q "resume-denied:validation" "$out" || fail "resume gap not rejected"

# 9. Permission expansion is denied (WM-FEAT-0236).
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" plugin_pack beta 1.1.0 \
  --permission secrets >/dev/null 2>&1 || fail "permission sign failed"
$oracle admit "$tmp/core.manifest.json" filesystem 1.0.0 0 0 0 >"$out" 2>&1
grep -q "denied:permission_expansion" "$out" || fail "permission expansion not denied"

# 10. Downgrade is denied (SPEC-020-R04) — a fresh plain manifest, so the
#     permission check cannot shadow the downgrade check.
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app stable 1.0.0 \
  >/dev/null 2>&1 || fail "downgrade sign failed"
$oracle admit "$tmp/core.manifest.json" none 9.0.0 0 0 0 >"$out" 2>&1
grep -q "denied:downgrade" "$out" || fail "downgrade not denied"

# 11. Crash loop quarantines; clean startup recovers (SPEC-020-R06).
$oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "crash loop not quarantined"
$oracle health 0,0,1 >"$out" 2>&1
grep -q "healthy" "$out" || fail "clean startup did not recover"

echo "failure EP-034 forced-failures: ok"
