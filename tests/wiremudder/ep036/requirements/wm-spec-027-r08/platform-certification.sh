#!/usr/bin/env sh
# WM-SPEC-027-R08: Windows, macOS, and Linux certification uses clean
# builds, tests, packaging, upgrade, rollback, and smoke evidence.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

# 1. The certification discipline is specified.
grep -q "WM-SPEC-027-R08" .agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md \
  || fail "SPEC-027 missing R08"

# 2. The Linux platform is certified with real evidence (clean build,
#    tests, packaging, upgrade, rollback, smoke) via the certification
#    suite that runs in this node.
sh tests/wiremudder/platform/linux-certification.sh >/dev/null 2>&1 \
  || fail "linux certification did not pass"

# 3. Upgrade/rollback/smoke evidence exists in the chaos + updater suites.
grep -q "crash loop quarantines and recovers" tests/wiremudder/chaos/fault-injection.sh \
  || fail "chaos suite missing rollback drill"
grep -q "upgrade pass preserved user data" installers/wiremudder/smoke.sh \
  || fail "installer smoke missing upgrade preservation"

# 4. Windows/macOS are documented with exact evidence requirements, not
#    claimed without evidence (honest matrix).
grep -q "## Windows" compatibility/platform/matrix.md || fail "matrix missing windows"
grep -q "## macOS" compatibility/platform/matrix.md || fail "matrix missing macos"
grep -q "development-only" compatibility/platform/matrix.md || fail "matrix missing dev-only"

echo "req WM-SPEC-027-R08: ok"
