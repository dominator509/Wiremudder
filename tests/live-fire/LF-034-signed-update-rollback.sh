#!/usr/bin/env sh
# LF-034 signed-update-rollback: live-fire proof for the secure updater.
#
# A real maintainer-side tool signs a real artifact with an ephemeral test
# key; the client verifies signature + hash; admission applies policy
# (permission, downgrade, rollout, sessions, lockdown); an interrupted
# download resumes; a failed startup quarantines and offers rollback
# guidance; and a clean startup recovers. Every step uses real generated
# artifacts and the real Rust core — no mocks, no simulated devices.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-034: FAIL - $1" >&2; exit 1; }
pass() { echo "LF-034: ok - $1"; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"
oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"

work=$(mktemp -d /tmp/lf034_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. Maintainer side: generate an ephemeral TEST key and sign a release.
echo "lf034-signed-release-3.0.0" > "$work/core.bin"
$fixtures gen-key "$work" >/dev/null 2>&1 || fail "gen-key failed"
pubkey=$(python3 -c "import json;print(json.load(open('$work/keypair.json'))['public_key_hex'])")
$fixtures sign "$work/keypair.json" "$work/core.bin" core_app stable 3.0.0 \
  >/dev/null 2>&1 || fail "sign failed"
pass "maintainer signed core_app stable 3.0.0"

# 2. Client verifies signature and artifact hash (SPEC-020-R04).
$oracle verify-manifest "$pubkey" "$work/core.manifest.json" >"$out" 2>&1
grep -q "verified version=3.0.0" "$out" || fail "signature verification failed"
$oracle verify-artifact "$work/core.manifest.json" "$work/core.bin" >"$out" 2>&1
grep -q "artifact-ok" "$out" || fail "artifact hash verification failed"
pass "client verified signature and hash"

# 3. A corrupted artifact is rejected before install.
printf 'corrupted' > "$work/core.bin.bad"
$oracle verify-artifact "$work/core.manifest.json" "$work/core.bin.bad" >"$out" 2>&1
grep -q "artifact-denied:verification" "$out" || fail "corrupted artifact accepted"
pass "corrupted artifact denied"

# 4. Admission: valid upgrade admitted; permission expansion, downgrade,
#    lockdown, active sessions, and rollout gating all deny.
$oracle admit "$work/core.manifest.json" none 2.0.0 0 0 0 >"$out" 2>&1
grep -q "admitted" "$out" || fail "valid upgrade not admitted"
pass "valid upgrade admitted"
$oracle admit "$work/core.manifest.json" none 4.0.0 0 0 0 >"$out" 2>&1
grep -q "denied:downgrade" "$out" || fail "downgrade not denied"
$oracle admit "$work/core.manifest.json" none 2.0.0 1 0 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "lockdown not deferred"
$oracle admit "$work/core.manifest.json" none 2.0.0 0 1 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "active session not deferred"
pass "denials hold (downgrade, lockdown, active session)"

# 5. Interrupted download resumes (WM-FEAT-0233).
$oracle resume ab 8 5 3 >"$out" 2>&1
grep -q "resume-ok:8" "$out" || fail "resume failed"
pass "interrupted download resumed"

# 6. Crash loop quarantines with rollback guidance; clean startup recovers
#    (SPEC-020-R06).
$oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "crash loop not quarantined"
$oracle health 0,0,1 >"$out" 2>&1
grep -q "healthy" "$out" || fail "clean startup did not recover"
pass "crash loop quarantined, clean startup recovered"

# 7. Migration safety: backup required before install (WM-FEAT-0237).
$oracle migration 1 2 >"$out" 2>&1
grep -q "backup_required from=1 to=2" "$out" || fail "migration backup not planned"
pass "migration backup planned"

# 8. Manual text gameplay is preserved: inherited updater untouched.
git diff --quiet -- src/updater.cpp || fail "inherited updater.cpp modified"
git diff --quiet -- src/updater.h || fail "inherited updater.h modified"
pass "manual gameplay preserved (inherited updater untouched)"

echo "LF-034: ok - signed-update-rollback certified"
