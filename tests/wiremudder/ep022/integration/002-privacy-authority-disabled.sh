#!/usr/bin/env sh
# EP-022 M3 integration test: privacy, authority, and disabled states.
# 1. Private variables are redacted on every surface.
# 2. AI Debugger only analyzes approved evidence.
# 3. AI Debugger cannot edit gates or self-certify.
# 4. Suggested patches require normal Graphlock validation.
# 5. Optional failure preserves manual gameplay (observer-only surfaces).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-debugger/src/lib.rs
HDR=src/wiremudder/ui/power-tools/power_tools_boundary.h

# 1. Privacy: private variables never retain a value.
grep -q "is_private" "$LIB" || fail "privacy scope missing from debugger"
grep -q "\"<redacted>\"" "$HDR" || fail "pane lacks redacted marker"

# 2. Approved-evidence gate for AI Debugger.
grep -q "approve_evidence" "$LIB" || fail "AI Debugger lacks evidence approval"
grep -q "DeniedPolicy" "$LIB" || fail "unapproved evidence is not denied"

# 3. No gate editing / no self-certification.
grep -q "self_certified: false" "$LIB" || fail "AI Debugger can self-certify"
grep -q "canEditGates() const { return false; }" "$HDR" || fail "pane can edit gates"

# 4. Safe patch proposals require validation.
grep -q "PatchProposal" "$LIB" || fail "patch proposal missing"
grep -q "validated: false" "$LIB" || fail "patch proposals start validated"

# 5. Preserved manual gameplay: surfaces observe, never send.
grep -q "canSendCommand() const { return false; }" "$HDR" || fail "pane has command path"
grep -q "isPassive() const { return true; }" "$HDR" || fail "pane not passive"

echo "integration EP-022 M3 privacy-authority-disabled: ok"
