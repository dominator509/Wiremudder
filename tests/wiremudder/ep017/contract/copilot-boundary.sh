#!/usr/bin/env sh
# EP-017 contract test: copilot boundary surfaces are real and locked by
# source evidence; the copilot consumes approved context (EP-015 capsules),
# routes through EP-016, and never hidden-sends commands.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Approved context surface exists (EP-015).
grep -q "pub struct ContextCapsule" wirecore/crates/wire-context/src/lib.rs \
  || fail "ContextCapsule surface missing"
grep -q "WM-SPEC-013-R02" .agent/specs/SPEC-013-context-distillation-token-budget-and-provider-routing.md \
  || fail "R02 spec surface missing"

# Provider router surface exists (EP-016).
grep -q "pub struct AiRouter" wirecore/crates/wire-ai-router/src/lib.rs \
  || fail "AiRouter surface missing"

# No hidden command send: SPEC-009 command safety is binding for the copilot.
grep -q "SPEC-009" .agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md \
  || fail "SPEC-009 not referenced by SPEC-014"

# Suggestion-only obligation present in the contract.
grep -q "never hidden-sends commands" .agent/node-contracts/EP-017.md \
  || fail "suggestion-only obligation missing"

# Evidence locks the UI boundary precedent AND the inherited build-list
# integration (WM-SRC-000114 pane pattern; WM-SRC-000118 mudlet_SRCS).
grep -qE '"symbol_or_range": *"TerminalPaneQt"' .agent/state/source-evidence.jsonl \
  || fail "no source evidence for UI boundary"
grep -qE '"symbol_or_range": *"mudlet_SRCS"' .agent/state/source-evidence.jsonl \
  || fail "no source evidence for build-list integration"
grep -q '"path":"src/CMakeLists.txt"' .agent/expected-files/EP-017.discovered.txt \
  || fail "discovered amendment missing src/CMakeLists.txt"

echo "contract copilot-boundary: ok"
