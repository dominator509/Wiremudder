#!/usr/bin/env sh
# WM-SPEC-020-R04: the updater rejects unsigned, invalid, corrupted,
# unexpected downgrade, incompatible, or permission-expanding artifacts.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"
oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"

tmp=$(mktemp -d /tmp/ep034_r04_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

$fixtures gen-key "$tmp" >/dev/null 2>&1 || fail "gen-key failed"
pubkey=$(python3 -c "import json;print(json.load(open('$tmp/keypair.json'))['public_key_hex'])")
echo "artifact" > "$tmp/core.bin"
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app stable 1.0.0 >/dev/null 2>&1 || fail "sign failed"

# Unsigned rejected.
python3 - <<PY
import json
p = '$tmp/core.manifest.json'
m = json.load(open(p)); m['signature'] = ''
json.dump(m, open(p, 'w'))
PY
$oracle verify-manifest "$pubkey" "$tmp/core.manifest.json" >"$out" 2>&1
grep -q "denied:verification" "$out" || fail "unsigned not rejected"

# Invalid (wrong key) rejected.
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app stable 1.0.0 >/dev/null 2>&1
$oracle verify-manifest "$(python3 -c "print('ef'*32)")" "$tmp/core.manifest.json" >"$out" 2>&1
grep -q "denied:verification" "$out" || fail "invalid signature not rejected"

# Corrupted (tampered artifact) rejected.
printf 'tampered' > "$tmp/bad.bin"
$oracle verify-artifact "$tmp/core.manifest.json" "$tmp/bad.bin" >"$out" 2>&1
grep -q "artifact-denied:verification" "$out" || fail "corrupted not rejected"

# Unexpected downgrade rejected.
$oracle admit "$tmp/core.manifest.json" none 9.0.0 0 0 0 >"$out" 2>&1
grep -q "denied:downgrade" "$out" || fail "downgrade not rejected"

# Permission-expanding rejected.
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" plugin_pack beta 1.1.0 \
  --permission network >/dev/null 2>&1
$oracle admit "$tmp/core.manifest.json" filesystem 1.0.0 0 0 0 >"$out" 2>&1
grep -q "denied:permission_expansion" "$out" || fail "permission expansion not rejected"

# Incompatible (schema version mismatch) rejected.
python3 - <<PY
import json
p = '$tmp/core.manifest.json'
m = json.load(open(p)); m['schema_version'] = 99
json.dump(m, open(p, 'w'))
PY
$oracle verify-manifest "$pubkey" "$tmp/core.manifest.json" >"$out" 2>&1
grep -q "denied:incompatibility" "$out" || fail "incompatible schema not rejected"

echo "req WM-SPEC-020-R04: ok"
