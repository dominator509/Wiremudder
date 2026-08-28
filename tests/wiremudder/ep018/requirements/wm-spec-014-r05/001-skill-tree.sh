#!/usr/bin/env sh
# WM-SPEC-014-R05: Agent Skill Tree lists installed skills, source,
# version, permissions, evaluation status, profile scope, and enable state.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r05: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-agents/src/lib.rs
grep -q "pub struct SkillRecord" "$LIB" || fail "SkillRecord missing"
grep -q "pub id: String" "$LIB" || fail "id missing"
grep -q "pub name: String" "$LIB" || fail "name missing"
grep -q "pub source: String" "$LIB" || fail "source missing"
grep -q "pub permissions: Vec<String>" "$LIB" || fail "permissions missing"
grep -q "pub evaluation_status: String" "$LIB" || fail "evaluation_status missing"
grep -q "pub profile_scope: String" "$LIB" || fail "profile_scope missing"
grep -q "pub enabled: bool" "$LIB" || fail "enabled missing"
grep -q "pub fn list" "$LIB" || fail "list missing"

# The schema declares the skill tree record fields.
SCHEMA=schemas/wiremudder/agents/skill-tree-v1.json
for field in source version permissions evaluation profile enabled; do
  grep -q "$field" "$SCHEMA" || fail "schema missing field $field"
done

echo "req WM-SPEC-014-R05: ok"
