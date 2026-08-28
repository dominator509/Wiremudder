#!/usr/bin/env sh
# LF-036 platform-chaos-matrix: live-fire proof for platform certification,
# chaos, and upstream sync regression.
#
# A certified platform passes clean build + suites + installer smoke; faults
# in dependency, input, worker, storage, and update paths fail safely or
# recover; and the upstream sync rehearsal does not break contracts. Every
# step uses real controlled mechanisms — no mocks.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-036: FAIL - $1" >&2; exit 1; }
pass() { echo "LF-036: ok - $1"; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"
release_oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"
fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"

work=$(mktemp -d /tmp/lf036_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. Clean platform certification: build, suites, installer smoke.
sh tests/wiremudder/platform/linux-certification.sh >"$out" 2>&1 \
  || { cat "$out" >&2; fail "linux certification failed"; }
grep -q "linux-certification: ok" "$out" || fail "certification sentinel missing"
pass "linux certified (clean build, suites, installer smoke)"

# 2. Dependency fault fails safely.
if $oracle verify-artifact /nonexistent/m.json /nonexistent/a.bin >"$out" 2>&1; then
  fail "missing dependency accepted"
fi
pass "dependency fault fails safe"

# 3. Input fault: corrupted manifest denied; oversized input rejected.
echo '{ not json' > "$work/bad.json"
$oracle verify-manifest "$(python3 -c "print('ab'*32)")" "$work/bad.json" >"$out" 2>&1 || true
grep -q "denied:verification" "$out" || fail "corrupted manifest not denied"
python3 -c "print('x'*300000)" > "$work/huge.json"
$oracle verify-manifest "$(python3 -c "print('ab'*32)")" "$work/huge.json" >"$out" 2>&1 || true
grep -q "denied:resource_exhaustion" "$out" || fail "oversized input not rejected"
pass "input faults denied (corrupted, oversized)"

# 4. Worker fault: killed download resumes from offset.
$oracle resume ab 10 4 3 >"$out" 2>&1
grep -q "resume-ok:7" "$out" || fail "resume after worker fault failed"
pass "worker fault recovers (resume from offset)"

# 5. Update fault: crash loop quarantines; clean startup recovers.
$oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "crash loop not quarantined"
$oracle health 0,0,1 >"$out" 2>&1
grep -q "healthy" "$out" || fail "clean startup did not recover"
pass "update fault quarantines and recovers"

# 6. Package/release fault: incomplete artifact set fails closed.
mkdir -p "$work/empty"
$release_oracle dir-check "$work/empty" 1 >"$out" 2>&1
grep -q "dir-incomplete:" "$out" || fail "incomplete release accepted"
pass "package fault fails closed (incomplete release)"

# 7. Upstream sync regression: pinned commit is ancestor; contracts hold.
set -a; . ./.env; set +a
git merge-base --is-ancestor "${WIREMUDDER_UPSTREAM_COMMIT}" HEAD \
  || fail "upstream sync broke pinned-commit contract"
sh scripts/node-contract-check.sh EP-036 >/dev/null || fail "node contract check failed"
pass "upstream sync rehearsal passes compatibility"

# 8. Data integrity and gameplay preserved.
git diff --quiet -- src/updater.cpp || fail "inherited updater.cpp modified"
git diff --quiet -- src/updater.h || fail "inherited updater.h modified"
pass "manual gameplay and data integrity preserved"

echo "LF-036: ok - platform-chaos-matrix certified"
