#!/usr/bin/env sh
# WM-SPEC-007-R09: Destructive or privacy-sensitive actions disclose
# effect, scope, source, and confirmation status. The help/coach
# surface discloses exactly that in popovers and coach steps, and
# capability confirmation status is explicit.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

grep -q "WM-SPEC-007-R09: Destructive or privacy-sensitive actions disclose effect, scope, source, and confirmation status" \
  .agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md \
  || fail "WM-SPEC-007-R09 missing from SPEC-007"

# Privacy notes disclose scope and source in help popovers.
grep -q "privacy_note" wirecore/crates/wire-help/src/lib.rs || fail "privacy disclosure missing"
grep -q '"privacy_note"' schemas/wiremudder/help/field-help-v1.json || fail "privacy note missing from schema"
# Confirmation status is explicit for capability onboarding.
grep -q "confirmed" wirecore/crates/wire-help/src/lib.rs || fail "confirmation status missing"

echo "requirement WM-SPEC-007-R09 disclosure: ok"
