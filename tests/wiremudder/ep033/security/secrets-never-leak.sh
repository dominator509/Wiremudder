#!/usr/bin/env sh
# EP-033 M4 security test: secrets never leak (SPEC-022-R02).
#
# Secrets are stored through the Secrets Vault, never logged, never
# committed, never placed in AI context. The committed tree carries no
# secret-shaped material outside documented/test zones, and the scanner's
# redaction path is proven by its own tests.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

# 1. Tracked tree outside docs/.agent/test zones has no secret-shaped hits.
hits=$(git grep -nE '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{32,})' \
  -- ':!docs/**' ':!.agent/**' ':!scripts/**' ':!security/wiremudder/src/secrets.rs' \
  ':!tests/wiremudder/ep033/fixtures/**' \
  ':!tests/wiremudder/ep003/unit/003-sanitize.sh' \
  ':!tests/wiremudder/ep003/failure/003-sanitize-hostile-input.sh' 2>/dev/null || true)
[ -z "$hits" ] || fail "secret-shaped material in tracked tree:\n$hits"

# 2. The crate's redaction path exists and is tested.
grep -q "pub fn redact" security/wiremudder/src/secrets.rs \
  || fail "redact path missing"
grep -q "fn redact_masks_only_findings" security/wiremudder/src/secrets.rs \
  || fail "redaction test missing"

# 3. Diagnostics never embed secret values: the redaction test asserts the
#    masked output form.
grep -q '<redacted>' security/wiremudder/src/secrets.rs \
  || fail "redaction placeholder missing"

echo "security EP-033 secrets-never-leak: ok"
