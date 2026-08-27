#!/usr/bin/env sh
# WM-SPEC-003-R08: every public behavior maps to a requirement ID,
# feature ID, node ID, test path, and live-fire proof.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "wm-spec-003-r08: FAIL - $1" >&2; exit 1; }

# Every requirement owned by this node must be routed in the validation
# matrix with a test path and a registered live-fire proof.
for req in WM-SPEC-003-R08 WM-SPEC-010-R10 WM-SPEC-011-R04 \
           WM-SPEC-011-R06 WM-SPEC-011-R07 WM-SPEC-011-R08 \
           WM-SPEC-023-R08 WM-SPEC-024-R02 WM-SPEC-026-R04 \
           WM-SPEC-026-R05 WM-SPEC-026-R06; do
  line=$(grep -P "^${req}\t" .agent/requirements/VALIDATION_MATRIX.tsv) \
    || fail "$req not routed in VALIDATION_MATRIX"
  printf '%s' "$line" | grep -q "EP-014" || fail "$req not owned by EP-014"
  printf '%s' "$line" | grep -q "LF-014" || fail "$req lacks LF-014 proof"
  test_path=$(printf '%s' "$line" | cut -f6)
  [ -n "$test_path" ] || fail "$req lacks test path"
done

# The requirement must appear in the node contract.
grep -q "WM-SPEC-003-R08" .agent/node-contracts/EP-014.md || fail "absent from contract"

echo "wm-spec-003-r08: ok"
