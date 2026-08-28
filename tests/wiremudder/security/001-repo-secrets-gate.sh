#!/usr/bin/env sh
# EP-033 shared security test boundary: the repository-wide secrets gate.
#
# This is the security/wiremudder/ boundary's contribution to the broad
# repository gates: it scans the tracked tree for secret-shaped material
# (private key blocks, AWS access key ids, OpenAI-style keys) using the
# deterministic wiremudder-security scanner semantics, excluding the
# intentional test fixtures that prove the scanner works.
set -eu
cd "$(dirname "$0")/../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

# Scan tracked files, excluding docs/ and .agent/ (documentation examples and
# graph files legitimately describe secret patterns), the test fixtures that
# intentionally prove detection, and the EP-003 hostile-input corpus whose own
# sanitize tests prove these example-shaped strings are redacted before any
# user-facing output.
hits=$(git grep -nE '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{32,})' \
  -- ':!docs/**' ':!.agent/**' ':!scripts/**' ':!security/wiremudder/src/secrets.rs' \
  ':!tests/wiremudder/ep033/fixtures/**' \
  ':!tests/wiremudder/ep003/unit/003-sanitize.sh' \
  ':!tests/wiremudder/ep003/failure/003-sanitize-hostile-input.sh' 2>/dev/null || true)
[ -z "$hits" ] || fail "secret-shaped material in tracked tree:\n$hits"

# The scanner's own test fixtures must be detected by the crate tests (proven
# there); here we assert the fixtures are confined to the test zone. Use a
# plain file grep (not git grep) because the crate is untracked until commit.
zone=$(grep -lE 'BEGIN (RSA|OPENSSH|EC) PRIVATE KEY' security/wiremudder/src/secrets.rs 2>/dev/null || true)
[ -n "$zone" ] || fail "secrets scanner fixture missing from test zone"

echo "security shared-boundary secrets-gate: ok"
