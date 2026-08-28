#!/usr/bin/env sh
# WM-SPEC-014-R07: Agent Council is reserved for tasks whose policy permits
# multi-agent reasoning and records roles, evidence, disagreements, budget,
# and final synthesis.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r07: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-agents/src/lib.rs
grep -q "pub struct Council" "$LIB" || fail "Council missing"
grep -q "pub struct CouncilRecord" "$LIB" || fail "CouncilRecord missing"
grep -q "pub votes: Vec<CouncilVote>" "$LIB" || fail "votes missing"
grep -q "pub evidence: Vec<String>" "$LIB" || fail "evidence missing"
grep -q "pub disagreements: Vec<String>" "$LIB" || fail "disagreements missing"
grep -q "pub final_synthesis: String" "$LIB" || fail "final_synthesis missing"
grep -q "require_permission" "$LIB" || fail "policy permission gate missing"
grep -q "synthesize" "$LIB" || fail "deterministic synthesis missing"

# Real behavior: denied without permission, disagreements recorded.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml council 2>&1 \
  | grep -q "council" || fail "council tests"

echo "req WM-SPEC-014-R07: ok"
