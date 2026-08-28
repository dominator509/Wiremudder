#!/usr/bin/env sh
# EP-036 M3 e2e test: the user-visible certification outcome — a platform
# is certified only with complete green evidence; a fault in the update
# path rolls back or quarantines; and an upstream sync does not break
# contracts.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-updater/Cargo.toml --bin wire-updater-oracle --"
fixtures="cargo run --quiet --release --manifest-path tools/update-fixtures/Cargo.toml --"

work=$(mktemp -d /tmp/ep036_e2e_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. A certified platform has complete green evidence: the Linux
#    certification suite passes end to end.
sh tests/wiremudder/platform/linux-certification.sh >"$out" 2>&1 \
  || { cat "$out" >&2; fail "linux certification failed"; }
grep -q "linux-certification: ok" "$out" || fail "certification sentinel missing"

# 2. An update fault rolls back or quarantines: crash loop quarantines and
#    offers rollback guidance; clean startup recovers.
$oracle health 0,0,0 >"$out" 2>&1
grep -q "crash_loop quarantined=true" "$out" || fail "crash loop not quarantined"
$oracle health 0,0,1 >"$out" 2>&1
grep -q "healthy" "$out" || fail "clean startup did not recover"

# 3. An upstream sync does not break contracts: pinned commit is ancestor
#    and the compatibility surface holds.
set -a; . ./.env; set +a
git merge-base --is-ancestor "${WIREMUDDER_UPSTREAM_COMMIT}" HEAD \
  || fail "upstream sync broke pinned-commit contract"
sh scripts/node-contract-check.sh EP-036 >/dev/null || fail "node contract check failed"

# 4. Manual gameplay is preserved: inherited client sources untouched.
git diff --quiet -- src/updater.cpp || fail "inherited updater.cpp modified"
git diff --quiet -- src/updater.h || fail "inherited updater.h modified"

echo "e2e EP-036 certification-outcome: ok"
