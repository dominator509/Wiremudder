#!/usr/bin/env sh
# WM-SPEC-000-R10: Auto-deployment is disabled by default and release
# signing remains maintainer-controlled. Proven with real layered
# evidence.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "r10: FAIL - $1" >&2; exit 1; }

# 1. Auto-deploy is false at the config layer.
set -a; . ./.env; set +a
[ "${WIREMUDDER_AUTO_DEPLOY:-false}" = false ] || fail "auto deploy must be false"

# 2. Auto-deploy is false at the probe layer: the probe is a boolean gate
#    (exit 0 = false/disabled) and must pass with the config sourced.
grep -q "WIREMUDDER_AUTO_DEPLOY" scripts/probes/auto_deploy.sh \
  || fail "auto_deploy probe missing"
set -a; . ./.env; set +a
sh scripts/probes/auto_deploy.sh || fail "auto_deploy probe reports enabled"

# 3. Auto-deploy is false at the production-readiness gate layer.
grep -q "auto deploy must remain false" scripts/production-readiness-check.sh \
  || fail "production gate lacks auto-deploy guard"

# 4. Signing remains maintainer-controlled: the agent-prepared candidate
#    is unsigned and the oracle refuses it for stable.
oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || fail "oracle binary missing"
cand=release/wiremudder/candidate
grep -q '"has_signature": false' "$cand/manifest.json" || fail "candidate signed by agent"
"$oracle" stable-check "$cand/manifest.json" | grep -q "stable-incomplete:.*signature" \
  || fail "stable must refuse unsigned candidate"

echo "requirement wm-spec-000-r10: ok"
