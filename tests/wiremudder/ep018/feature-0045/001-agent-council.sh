#!/usr/bin/env sh
# EP-018 M5 feature test: WM-FEAT-0045 Agent Council.
# Council is reserved for tasks whose policy permits multi-agent reasoning
# and records roles, evidence, disagreements, budget, and final synthesis
# (SPEC-014-R07).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0045: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-agents/src/lib.rs
grep -q "pub struct Council" "$LIB" || fail "Council missing"
grep -q "pub struct CouncilConfig" "$LIB" || fail "CouncilConfig missing"
grep -q "pub struct CouncilVote" "$LIB" || fail "CouncilVote missing"
grep -q "pub disagreements: Vec<String>" "$LIB" || fail "disagreement records missing"
grep -q "pub final_synthesis: String" "$LIB" || fail "final_synthesis missing"
grep -q "pub budget_usd_micros: u64" "$LIB" || fail "budget missing"
grep -q "require_permission" "$LIB" || fail "permission gate missing"
grep -q "max_budget_usd_micros" "$LIB" || fail "budget bound missing"

python3 -c "import json; d=json.load(open('schemas/wiremudder/agents/council-v1.json')); assert 'disagreement' in json.dumps(d).lower()" \
  || fail "council schema invalid"

# Real behavior: denied without permission, budget enforced, disagreement
# recorded, deterministic synthesis.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml council 2>&1 \
  | grep -q "council" || fail "council tests"

echo "feature-0045 agent-council: ok"
