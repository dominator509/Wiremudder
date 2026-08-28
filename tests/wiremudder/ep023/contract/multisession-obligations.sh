#!/usr/bin/env sh
# EP-023 M1 contract test: multi-session fairness and shared policy
# gates. Fails if session fairness, JSONL/scenario validation, supervisor
# risk/health reporting, or cross-session rule auditing is absent from
# the accepted contract.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

CONTRACT=.agent/node-contracts/EP-023.md

# Acceptance obligations 1-6 must be present verbatim.
grep -q "Desktop sessions cannot starve each other" "$CONTRACT" || fail "session fairness obligation missing"
grep -q "Headless shares policy and privacy contracts" "$CONTRACT" || fail "shared policy obligation missing"
grep -q "JSONL and scenarios validate" "$CONTRACT" || fail "JSONL/scenario validation obligation missing"
grep -q "Supervisor accurately reports risk and health" "$CONTRACT" || fail "supervisor reporting obligation missing"
grep -q "Cross-session rules are explicit and audited" "$CONTRACT" || fail "cross-session audit obligation missing"
grep -q "Headless uses less resource than desktop equivalent" "$CONTRACT" || fail "headless resource obligation missing"

echo "contract EP-023 multisession-obligations: ok"
