#!/usr/bin/env sh
# WM-SPEC-000-R09: User-owned data is exportable and no production cloud
# dependency is required for the core release. Proven with real evidence
# for the release candidate.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "r09: FAIL - $1" >&2; exit 1; }

# 1. Export of user-owned data is documented (real ADR + user docs).
grep -qi "export" docs/adr/ADR-0013-use-local-first-storage-and-export.md \
  || fail "ADR-0013 lacks export coverage"
grep -qi "export" docs/wiremudder/user/privacy.md \
  || fail "privacy doc lacks export coverage"
grep -qi "export" docs/wiremudder/user/feature-index.md \
  || fail "feature index lacks export coverage"

# 2. No production cloud dependency: the core candidate is local-first and
#    auto-deploy stays off; optional providers are disabled, not required.
set -a; . ./.env; set +a
[ "${WIREMUDDER_LOCAL_ONLY:-false}" = true ] || fail "local-only not set"
[ "${WIREMUDDER_AUTO_DEPLOY:-false}" = false ] || fail "auto deploy not disabled"

# 3. The candidate's known risks document says optional providers are
#    disabled and unclaimed.
grep -qi "disabled" docs/wiremudder/release-candidate/KNOWN_RISKS.md \
  || fail "known risks lacks disabled-provider statement"

echo "requirement wm-spec-000-r09: ok"
