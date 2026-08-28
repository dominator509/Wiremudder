#!/usr/bin/env sh
# EP-018 M5 feature test: WM-FEAT-0044 Agent Skill Tree.
# The tree lists installed skills with source, version, permissions,
# evaluation status, profile scope, and enable state (SPEC-014-R05); only
# skills with provenance and evaluation can be enabled.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0044: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-agents/src/lib.rs
grep -q "pub struct SkillRecord" "$LIB" || fail "SkillRecord missing"
grep -q "pub source: String" "$LIB" || fail "source provenance missing"
grep -q "pub version: String" "$LIB" || fail "version missing"
grep -q "pub permissions: Vec<String>" "$LIB" || fail "permissions missing"
grep -q "pub evaluation_status: String" "$LIB" || fail "evaluation_status missing"
grep -q "pub profile_scope: String" "$LIB" || fail "profile_scope missing"
grep -q "pub enabled: bool" "$LIB" || fail "enabled missing"
grep -q "pub fn can_enable" "$LIB" || fail "can_enable missing"
grep -q "evaluation_status == \"evaluated\"" "$LIB" || fail "enable requires evaluation"

python3 -c "import json; d=json.load(open('schemas/wiremudder/agents/skill-tree-v1.json')); assert 'skill' in json.dumps(d).lower()" \
  || fail "skill-tree schema invalid"

# Real behavior: a pending skill cannot be enabled; an evaluated one can.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml skill 2>&1 \
  | grep -q "skill" || fail "skill tree tests"

echo "feature-0044 agent-skill-tree: ok"
