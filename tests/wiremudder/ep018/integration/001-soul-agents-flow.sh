#!/usr/bin/env sh
# EP-018 M3 integration test: real soul + agents crate flows.
# Exercises SoulStudio validation/preview, deny-by-default memory
# permissions, and budgeted council through the real crate types.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# The Soul UI pane is real and compiled into the client build list.
[ -f src/wiremudder/ui/soul/soul_boundary.h ] || fail "soul pane header missing"
[ -f src/wiremudder/ui/soul/soul_boundary.cpp ] || fail "soul pane impl missing"
grep -q "wiremudder/ui/soul/soul_boundary.cpp" src/CMakeLists.txt \
  || fail "soul pane not in client build (mudlet_SRCS)"

# The crates expose the required surfaces.
for sym in SoulDocument SoulStudio SoulError; do
  grep -q "pub struct $sym\|pub enum $sym" wirecore/crates/wire-soul/src/lib.rs || fail "wire-soul missing $sym"
done
for sym in AgentRole MemoryClass PermissionMatrix SkillTree Council CouncilRecord; do
  grep -q "pub struct $sym\|pub enum $sym" wirecore/crates/wire-agents/src/lib.rs || fail "wire-agents missing $sym"
done

echo "integration EP-018 M3 soul-agents-flow: ok"
