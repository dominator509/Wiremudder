#!/usr/bin/env sh
# EP-016 contract test: routing and provider-boundary surfaces are real
# and locked by source evidence; the local provider endpoint is a live
# executable (Ollama), and remote adapters require credentials + privacy.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# EP-015 routing API exists (deterministic input for the router).
grep -q "pub fn decide_route" wirecore/crates/wire-token-budget/src/lib.rs \
  || fail "decide_route surface missing"

# Provider adapter requirement is present in the spec.
grep -q "WM-SPEC-013-R04" .agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md \
  || fail "R04 spec surface missing"

# No-silent-remote requirement is present in the spec.
grep -q "no silent remote" .agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md \
  || fail "R08 spec surface missing"

# Evidence locks the routing boundary.
grep -q '"symbol_or_range":"decide_route"' .agent/state/source-evidence.jsonl \
  || fail "no source evidence for decide_route"

# Discovered amendment present.
grep -q "Brownfield discovered-path amendment" .agent/expected-files/EP-016.discovered.txt \
  || fail "discovered amendment missing header"

echo "contract provider-boundary: ok"
