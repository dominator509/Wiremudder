#!/usr/bin/env sh
# WM-SPEC-014-R02: Specialized agents include mapper/cartographer, lore/
# memory curator, quest, tactical, renderer scene, voice companion,
# help/setup, command safety, token budget, and privacy firewall roles.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r02: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-agents/src/lib.rs
for role in Mapper Cartographer LoreCurator Quest Tactical RendererScene \
            VoiceCompanion HelpSetup CommandSafety TokenBudget PrivacyFirewall; do
  grep -q "$role," "$LIB" || fail "missing role $role"
done
grep -q "pub const ALL" "$LIB" || fail "role registry missing"
grep -q 'AgentRole::ALL.len(), 11' "$LIB" || fail "all 11 roles not asserted"

# Real behavior: the registry serializes and round-trips every role key.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml \
  --example e2e_soul_agents 2>&1 | grep -q "E2E soul-agents: ok" \
  || fail "e2e soul-agents (role registry)"

echo "req WM-SPEC-014-R02: ok"
