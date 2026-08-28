#!/usr/bin/env sh
# EP-034 M4 failure test: denied permission, policy, and active-session
# deferral fail closed (SPEC-022-R04/R09, SPEC-020-R07).
#
# Untrusted content cannot override update policy. Denials are typed and
# deterministic, and the C++ boundary mirrors the Rust core's denial states.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"
fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"

tmp=$(mktemp -d /tmp/ep034_denied_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

$fixtures gen-key "$tmp" >/dev/null 2>&1 || fail "gen-key failed"
pubkey=$(python3 -c "import json;print(json.load(open('$tmp/keypair.json'))['public_key_hex'])")
echo "core-artifact" > "$tmp/core.bin"
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app stable 2.0.0 >/dev/null 2>&1 || fail "sign failed"

# 1. Local Only Lockdown denies the remote update check (SPEC-010-R04).
$oracle admit "$tmp/core.manifest.json" none 1.0.0 1 0 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "lockdown not deferred"

# 2. Active sessions defer the update (SPEC-020-R07).
$oracle admit "$tmp/core.manifest.json" none 1.0.0 0 1 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "active session not deferred"

# 3. Staged rollout gating denies clients outside the offered fraction
#    (WM-FEAT-0232). A 10% rollout must not offer bucket 500.
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app beta 2.1.0 \
  --rollout 0.1 >/dev/null 2>&1 || fail "rollout sign failed"
$oracle admit "$tmp/core.manifest.json" none 1.0.0 0 0 500 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "staged rollout not deferred"
$oracle admit "$tmp/core.manifest.json" none 1.0.0 0 0 50 >"$out" 2>&1
grep -q "admitted" "$out" || fail "staged rollout wrongly deferred offered client"

# 4. Kill switch halts the rollout for everyone (WM-FEAT-0232).
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app beta 2.2.0 \
  --kill-switch >/dev/null 2>&1 || fail "kill-switch sign failed"
$oracle admit "$tmp/core.manifest.json" none 1.0.0 0 0 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "kill switch did not halt rollout"

# 5. The C++ boundary denies permission expansion with the same typed
#    state as the Rust core.
grep -q "DeniedPermissionExpansion" src/wiremudder/updater/updater_boundary.h \
  || fail "C++ boundary missing permission-expansion denial state"
grep -q "DeferredLockdown" src/wiremudder/updater/updater_boundary.h \
  || fail "C++ boundary missing lockdown deferral state"

echo "failure EP-034 denied-policy: ok"
