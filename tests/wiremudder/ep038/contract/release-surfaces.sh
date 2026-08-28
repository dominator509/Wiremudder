#!/usr/bin/env sh
# EP-038 M1 contract test: the release-candidate surfaces this node builds
# on exist and carry the exact anchors the contract requires — the pinned
# upstream commit, all dependency nodes green, auto-deploy false, and the
# release gates.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Provenance anchor: pinned upstream commit.
[ -f UPSTREAM.lock.yaml ] || fail "missing UPSTREAM.lock.yaml"
grep -q "development_commit" UPSTREAM.lock.yaml || fail "lock missing development_commit"
[ -f .env ] || fail "missing .env"
set -a; . ./.env; set +a
[ -n "${WIREMUDDER_UPSTREAM_COMMIT:-}" ] || fail "pinned commit env missing"
git cat-file -e "${WIREMUDDER_UPSTREAM_COMMIT}^{commit}" 2>/dev/null \
  || fail "pinned commit not present"

# All dependency nodes have green tags (WM-SPEC-028-R01).
for dep in EP-029 EP-032 EP-033 EP-035 EP-036 EP-037; do
  git rev-parse -q --verify "refs/tags/green/$dep" >/dev/null \
    || fail "dependency $dep not green"
done

# Auto-deploy is disabled by default (WM-SPEC-000-R10).
[ "${WIREMUDDER_AUTO_DEPLOY:-false}" = false ] \
  || fail "auto deploy must remain false"
[ -f scripts/probes/auto_deploy.sh ] || fail "missing auto_deploy probe"

# Owning specs exist.
for s in SPEC-000-product-scope-and-release-profiles \
         SPEC-020-updates-packages-supply-chain-and-release \
         SPEC-022-security-privacy-threat-model-and-abuse-boundaries \
         SPEC-027-testing-oracles-performance-and-platform-certification \
         SPEC-028-production-readiness-ship-and-maintenance; do
  [ -f ".agent/specs/$s.md" ] || fail "missing spec $s"
done

echo "contract EP-038 release-surfaces: ok"
