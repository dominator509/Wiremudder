#!/usr/bin/env sh
# WM-FEAT-0133: future autonomous bug remediation (research-decision-required).
# The capability is not certified for autonomous production use: the live
# fallback produces a human-reviewed diagnostic and patch plan only.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0133: FAIL - $1" >&2; exit 1; }

grep -q "WM-FEAT-0133" .agent/features/FEATURES.tsv || fail "feature missing from FEATURES.tsv"
grep -q "future" .agent/features/FEATURES.tsv || fail "feature not marked future"

# The fallback is declared in the node contract: no automatic production
# edit, only a human-reviewed diagnostic and patch plan.
grep -q "Generate a human-reviewed diagnostic and patch plan only; do not edit production code automatically" \
  .agent/node-contracts/EP-029.md || fail "human-reviewed fallback not declared"

# The workflow never edits production code: it only plans patches.
grep -q "patch" .agent/node-contracts/EP-029.md || fail "patch planning missing from contract"

echo "feature-0133: ok"
