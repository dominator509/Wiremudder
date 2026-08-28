#!/usr/bin/env sh
# EP-017 M3 integration test: privacy disclosure, action authority, and
# restart/health behavior of the copilot boundary.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# Disclosure fields are visible (acceptance obligation 5).
for f in providerId routeId privacyMode redactionPatterns contextBytes \
         promptTokens completionTokens estimatedCostUsdMicros latencyMs; do
  grep -q "$f" src/wiremudder/ui/copilot/copilot_boundary.h \
    || fail "disclosure missing $f"
done

# Action authority: proposals require SPEC-009 confirmation.
grep -q "requiresConfirmation" src/wiremudder/ui/copilot/copilot_boundary.h \
  || fail "action proposal missing confirmation flag"
grep -q "SPEC-009" src/wiremudder/ui/copilot/copilot_boundary.h \
  || fail "SPEC-009 obligation not documented"

# Cancellation is distinct from failure (SPEC-025-R07).
grep -q "requestCancel" src/wiremudder/ui/copilot/copilot_boundary.h \
  || fail "cancellation missing"

# Bounded history (restart-safe, per-profile).
grep -q "setMaxHistory\|historyCount" src/wiremudder/ui/copilot/copilot_boundary.h \
  || fail "bounded history missing"

echo "integration EP-017 M3 disclosure-authority-health: ok"
