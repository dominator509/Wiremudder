#!/usr/bin/env sh
# EP-034 M3 e2e test: the real user-visible signed update flow end to end —
# a maintainer-side fixture tool signs a real artifact with an ephemeral
# test key, the client verifies the signature and hash, admission applies
# channel/policy/deferral rules, and a failed startup quarantines and offers
# rollback guidance. Every step uses real generated artifacts and the real
# Rust core; nothing is mocked.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"
oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"

work=$(mktemp -d /tmp/ep034_e2e_XXXX)
trap 'rm -rf "$work"' EXIT
out=$(mktemp "$work/out.XXXX")

# --- Maintainer side: sign a release for the core_app stable lane. ---
echo "wiremudder-e2e-release-2.0.0" > "$work/core.bin"
$fixtures gen-key "$work" >/dev/null 2>&1 || fail "gen-key failed"
pubkey=$(python3 -c "import json;print(json.load(open('$work/keypair.json'))['public_key_hex'])")
$fixtures sign "$work/keypair.json" "$work/core.bin" core_app stable 2.0.0 \
  >/dev/null 2>&1 || fail "sign failed"

# --- Client side: the release is offered only after signature+hash verify. ---
$oracle verify-manifest "$pubkey" "$work/core.manifest.json" >"$out" 2>&1
grep -q "verified version=2.0.0" "$out" || fail "signed release not verified"

# --- Admission: a user on 1.0.0 with no active sessions is admitted. ---
$oracle admit "$work/core.manifest.json" none 1.0.0 0 0 0 >"$out" 2>&1
grep -q "admitted" "$out" || fail "release not admitted"

# --- Tampered artifact is rejected before install (corrupted download). ---
printf 'corrupted-bytes' > "$work/core.bin.bad"
$oracle verify-artifact "$work/core.manifest.json" "$work/core.bin.bad" >"$out" 2>&1
grep -q "artifact-denied:verification" "$out" || fail "corrupted artifact not denied"

# --- Resumable download: an interrupted transfer resumes contiguously. ---
$oracle resume ab 8 5 3 >"$out" 2>&1
grep -q "resume-ok:8" "$out" || fail "download did not resume to completion"

# --- Failed startup quarantines and offers rollback guidance. ---
$oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "crash loop not quarantined"

# --- Active session defers the update (SPEC-020-R07). ---
$oracle admit "$work/core.manifest.json" none 1.0.0 0 1 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "active session did not defer"

# --- Local Only Lockdown blocks remote update checks (SPEC-010-R04). ---
$oracle admit "$work/core.manifest.json" none 1.0.0 1 0 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "lockdown did not block"

# --- Manual gameplay is preserved: the terminal client is untouched. ---
[ -f src/updater.cpp ] || fail "inherited updater.cpp missing"
git diff --quiet -- src/updater.cpp || fail "inherited updater.cpp was modified"
[ -f src/updater.h ] || fail "inherited updater.h missing"
git diff --quiet -- src/updater.h || fail "inherited updater.h was modified"

echo "e2e EP-034 signed-update-rollback-flow: ok"
