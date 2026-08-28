#!/usr/bin/env sh
# EP-036 M3 integration test: the certification harness integrates with the
# real repository — clean platform build, full suites, packaging, upgrade,
# rollback, and smoke — and upstream sync regression passes compatibility.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

# 1. Clean build + full suites (platform certification real run).
sh tests/wiremudder/platform/linux-certification.sh >/dev/null 2>&1 \
  || fail "platform certification failed"

# 2. Upstream sync regression: pinned commit is an ancestor of HEAD.
set -a; . ./.env; set +a
git merge-base --is-ancestor "${WIREMUDDER_UPSTREAM_COMMIT}" HEAD \
  || fail "upstream sync regression: pinned commit not ancestor"

# 3. Certification design doc exists and documents the evidence chain.
[ -f docs/wiremudder/certification/design/platform-certification.md ] \
  || fail "missing certification design doc"
grep -q "SPEC-027-R08" docs/wiremudder/certification/design/platform-certification.md \
  || fail "design doc missing SPEC-027-R08"

# 4. The compatibility matrix records honest platform status.
grep -q "certified" compatibility/platform/matrix.md || fail "matrix missing certified status"
grep -q "development-only" compatibility/platform/matrix.md || fail "matrix missing dev-only status"

# 5. Chaos integration: fault injection runs against real cores and
#    preserves gameplay.
sh tests/wiremudder/chaos/fault-injection.sh >/dev/null 2>&1 \
  || fail "chaos fault injection failed"

echo "integration EP-036 certification-harness: ok"
