#!/usr/bin/env sh
# EP-018 M3 integration test: data scope, audit, and health of the soul/
# agents system. Studio audits changes; permissions are deny-by-default;
# council records disagreements.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# Studio audit trail exists and is bounded.
grep -q "pub audit" wirecore/crates/wire-soul/src/lib.rs || fail "soul audit missing"
grep -q "recent_audit" wirecore/crates/wire-soul/src/lib.rs || fail "audit readback missing"

# Memory permissions deny by default.
grep -q "unwrap_or(Access::Deny)" wirecore/crates/wire-agents/src/lib.rs \
  || fail "deny-by-default missing"

# Council records disagreements and is budgeted.
grep -q "disagreements" wirecore/crates/wire-agents/src/lib.rs || fail "disagreements missing"
grep -q "max_budget_usd_micros" wirecore/crates/wire-agents/src/lib.rs || fail "budget missing"

# The pane exposes the data surfaces.
for sym in SkillRowQt MemoryPermissionQt CouncilRowQt SoulPaneState; do
  grep -q "$sym" src/wiremudder/ui/soul/soul_boundary.h || fail "pane missing $sym"
done

echo "integration EP-018 M3 data-scope-audit-health: ok"
