#!/usr/bin/env sh
# EP-039 M2 unit test: AUTO_DEPLOY must be false at every real layer and the
# final release directory must never contain a signing key or secret.
set -eu
cd "$(dirname "$0")/../../../.."

# 1. AUTO_DEPLOY=false at the three real layers the release reads.
[ -f .env ] && { set -a; . ./.env; set +a; }
[ "${WIREMUDDER_AUTO_DEPLOY:-}" = "false" ] \
  || { echo "FAIL: WIREMUDDER_AUTO_DEPLOY not false (.env)" >&2; exit 1; }
[ -f scripts/probes/auto_deploy.sh ] || { echo "FAIL: auto_deploy probe missing" >&2; exit 1; }
# The probe asserts auto-deploy IS false: exit 0 confirms the safe state.
sh scripts/probes/auto_deploy.sh >/dev/null 2>&1 \
  || { echo "FAIL: auto_deploy probe did not confirm false" >&2; exit 1; }
# The structural readiness check verifies EP-000..EP-038 are complete; it must
# PASS here (all prior nodes are done), while auto-deploy stays false.
python3 scripts/production_readiness.py >/dev/null 2>&1 \
  || { echo "FAIL: production readiness structural check must pass (prior nodes done)" >&2; exit 1; }

# 2. No secret material in the final release boundary.
if find release/wiremudder/final -type f 2>/dev/null | grep -qiE '\.(pem|key|p12|pfx)$|secret'; then
  echo "FAIL: secret-looking file in final release" >&2
  exit 1
fi

echo 'auto-deploy lockdown: ok'
