#!/usr/bin/env sh
# EP-036 M4 failure test: certification/chaos forced failures fail closed
# (SPEC-025, SPEC-027).
#
# Real controlled failures: malformed inputs, missing dependencies,
# incomplete releases, crash loops, and oversized data. Each must produce a
# typed error — never a false success.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"
release_oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"
fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"

tmp=$(mktemp -d /tmp/ep036_fail_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

# 1. Malformed manifest denied.
echo '{ not json' > "$tmp/bad.json"
$oracle verify-manifest "$(python3 -c "print('ab'*32)")" "$tmp/bad.json" >"$out" 2>&1 || true
grep -q "denied:verification" "$out" || fail "malformed manifest not denied"

# 2. Oversized input rejected (resource exhaustion).
python3 -c "print('x'*300000)" > "$tmp/huge.json"
$oracle verify-manifest "$(python3 -c "print('ab'*32)")" "$tmp/huge.json" >"$out" 2>&1 || true
grep -q "denied:resource_exhaustion" "$out" || fail "oversized input not rejected"

# 3. Missing dependency fails closed.
if $oracle verify-artifact /nonexistent/m.json /nonexistent/a.bin >"$out" 2>&1; then
  cat "$out" >&2; fail "missing dependency accepted"
fi

# 4. Incomplete release fails closed.
mkdir -p "$tmp/empty"
$release_oracle dir-check "$tmp/empty" 1 >"$out" 2>&1
grep -q "dir-incomplete:" "$out" || fail "incomplete release accepted"

# 5. Crash loop quarantines; clean startup recovers (SPEC-020-R06).
$oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "crash loop not quarantined"
$oracle health 0,0,1 >"$out" 2>&1
grep -q "healthy" "$out" || fail "clean startup did not recover"

# 6. Denied policy: lockdown and active sessions defer.
$fixtures gen-key "$tmp" >/dev/null 2>&1 || fail "gen-key failed"
echo "artifact" > "$tmp/core.bin"
$fixtures sign "$tmp/keypair.json" "$tmp/core.bin" core_app stable 1.0.0 >/dev/null 2>&1
$oracle admit "$tmp/core.manifest.json" none 0.9.0 1 0 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "lockdown not deferred"
$oracle admit "$tmp/core.manifest.json" none 0.9.0 0 1 0 >"$out" 2>&1
grep -q "denied:deferred" "$out" || fail "active session not deferred"

# 7. Data integrity: inherited gameplay sources untouched by all faults.
git diff --quiet -- src/updater.cpp || fail "inherited updater.cpp modified"
git diff --quiet -- src/updater.h || fail "inherited updater.h modified"

echo "failure EP-036 forced-failures: ok"
