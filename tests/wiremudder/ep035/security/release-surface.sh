#!/usr/bin/env sh
# EP-035 M4 security test: release security obligations (SPEC-020-R09,
# SPEC-022, SPEC-028).
#
# 1. Agents never sign: the release core has no signing key material in
#    production code and the provenance records agent preparation.
# 2. No secret material is printed by the release core.
# 3. Stable publication is manual: AUTO_DEPLOY is false and the inherited
#    release workflow gates on maintainer conditions.
# 4. Release-candidate storage is optional and env-configured.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

# 1. The release core never signs in production code: no signing-key
#    material (only the maintainer-signing boundary flag).
grep -q "SigningKey\|ed25519\|secret_key" packaging/wiremudder/src/lib.rs \
  && fail "release core contains signing material" || true
grep -q "signed_by_maintainer" packaging/wiremudder/src/lib.rs \
  || fail "core missing maintainer-signing boundary"
grep -q "prepared_by_agent" packaging/wiremudder/src/lib.rs \
  || fail "core missing agent-prepared marker"

# 2. No secret-shaped output from the core oracle.
if grep -rn "println!\|eprintln!" packaging/wiremudder/src/lib.rs | grep -qi "secret\|key\|token"; then
  fail "core prints secret material"
fi

# 3. Stable publication is manual (WIREMUDDER_AUTO_DEPLOY false / manual
#    publish rule).
grep -q "requires_manual_publish" packaging/wiremudder/src/lib.rs \
  || fail "core missing manual-publish rule"
grep -q "WIREMUDDER_AUTO_DEPLOY=false" .env \
  || fail "WIREMUDDER_AUTO_DEPLOY must be false in .env"

# 4. Release-candidate storage is optional env configuration.
[ -f .agent/preflight/EP-035-release-storage.env.example ] \
  || fail "missing release-storage env example"
grep -q "WIREMUDDER_RC_ARTIFACT_BUCKET" .agent/preflight/EP-035-release-storage.env.example \
  || fail "release-storage env missing bucket var"

# 5. The inherited release workflow is untouched (no agent publish path).
[ -f .github/workflows/create-github-release.yml ] || fail "missing inherited release workflow"
grep -q "repository_owner == 'Mudlet'" .github/workflows/create-github-release.yml \
  || fail "inherited workflow owner gate missing"

echo "security EP-035 release-surface: ok"
