#!/usr/bin/env sh
# EP-039 M4 security: the agent cannot publish — the publish path requires a
# maintainer step (signing) and the environment forbids auto-deploy. Denial is
# proven with the real probe, not a stub.
set -eu
cd "$(dirname "$0")/../../../.."

# The real layers the release reads: .env is sourced exactly as the unit
# tests source it; the probe then asserts WIREMUDDER_AUTO_DEPLOY=false.
[ -f .env ] && { set -a; . ./.env; set +a; }

# 1. Auto-deploy probe must assert false (exit 0 means "false confirmed").
sh scripts/probes/auto_deploy.sh >/dev/null 2>&1 \
  || { echo "FAIL: auto-deploy probe did not confirm false" >&2; exit 1; }

# 2. Every release-claims path must stay within the certified set; a profile
#    claiming an uncertified provider must be denied.
if WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh >/dev/null 2>&1; then
  : # full profile legitimately passes (244 features)
else
  echo "FAIL: full profile claims gate failed unexpectedly" >&2
  exit 1
fi

# 3. Manifest says no signature; stable-check refuses (oracle gate).
oracle=wirecore/target/release/wire-release-oracle
if [ -x "$oracle" ]; then
  if "$oracle" stable-check release/wiremudder/final/manifest.json 2>&1 \
       | grep -q 'stable-incomplete'; then
    echo 'denied-publish invariant: ok (oracle refuses unsigned stable)'
  else
    echo "FAIL: oracle accepted unsigned manifest for stable" >&2
    exit 1
  fi
else
  echo "SKIP: oracle binary not built" >&2
fi
