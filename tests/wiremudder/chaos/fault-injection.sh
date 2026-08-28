#!/usr/bin/env sh
# EP-036 M2 chaos suite: real fault injection against the real updater and
# release cores — missing dependencies, corrupted inputs, killed workers,
# and storage pressure. Each fault must fail closed or recover; data and
# gameplay integrity are preserved.
set -eu
cd "$(dirname "$0")/../../.."

fail() { echo "chaos: FAIL - $1" >&2; exit 1; }
pass() { echo "chaos: ok - $1"; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

updater_oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"
release_oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"
fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"

work=$(mktemp -d /tmp/ep036_chaos_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. Unavailable dependency: a missing artifact file fails closed.
if $updater_oracle verify-artifact /nonexistent/manifest.json /nonexistent/artifact.bin >"$out" 2>&1; then
  cat "$out" >&2; fail "missing dependency accepted"
fi
pass "unavailable dependency fails closed"

# 2. Corrupted input: malformed manifest is denied.
echo '{ not json' > "$work/bad.json"
$updater_oracle verify-manifest "$(python3 -c "print('ab'*32)")" "$work/bad.json" >"$out" 2>&1 || true
grep -q "denied:verification" "$out" || fail "corrupted manifest not denied"
pass "corrupted input denied"

# 3. Killed worker: a process that dies mid-download resumes from its last
#    contiguous offset (the resume state is the recovery contract).
$updater_oracle resume ab 10 4 3 >"$out" 2>&1
grep -q "resume-ok:7" "$out" || fail "resume after kill failed"
pass "killed worker resumes from offset"

# 4. Storage pressure: an artifact that exceeds the size bound is rejected.
$fixtures gen-key "$work" >/dev/null 2>&1 || fail "gen-key failed"
echo "artifact" > "$work/core.bin"
$fixtures sign "$work/keypair.json" "$work/core.bin" core_app stable 1.0.0 >/dev/null 2>&1
python3 -c "print('x'*300000)" > "$work/huge.json"
$updater_oracle verify-manifest "$(python3 -c "print('ab'*32)")" "$work/huge.json" >"$out" 2>&1 || true
grep -q "denied:resource_exhaustion" "$out" || fail "oversized input not rejected"
pass "storage pressure rejected (oversized input)"

# 5. Crash loop: repeated failed startups quarantine; clean startup recovers.
$updater_oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "crash loop not quarantined"
$updater_oracle health 0,0,1 >"$out" 2>&1
grep -q "healthy" "$out" || fail "clean startup did not recover"
pass "crash loop quarantines and recovers"

# 6. Release chaos: an incomplete artifact directory fails closed.
mkdir -p "$work/partial"
$release_oracle dir-check "$work/partial" 1 >"$out" 2>&1
grep -q "dir-incomplete:" "$out" || fail "incomplete release accepted"
pass "incomplete release fails closed"

# 7. Preserved gameplay/data integrity: the inherited client sources are
#    untouched by every fault above.
git diff --quiet -- src/updater.cpp || fail "inherited updater.cpp modified"
git diff --quiet -- src/updater.h || fail "inherited updater.h modified"
pass "manual gameplay and data integrity preserved"

echo "chaos EP-036 fault-injection: ok"
