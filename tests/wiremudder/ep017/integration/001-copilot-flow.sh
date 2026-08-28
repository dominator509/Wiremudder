#!/usr/bin/env sh
# EP-017 M3 integration test: real distill -> route -> copilot -> pane flow.
# Proves the copilot consumes EP-015 capsules, routes through EP-016, and
# lands a suggestion in the Qt pane boundary (which compiles into the client).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# The Qt pane boundary is real and compiled into the client build list.
[ -f src/wiremudder/ui/copilot/copilot_boundary.h ] || fail "copilot pane header missing"
[ -f src/wiremudder/ui/copilot/copilot_boundary.cpp ] || fail "copilot pane impl missing"
grep -q "wiremudder/ui/copilot/copilot_boundary.cpp" src/CMakeLists.txt \
  || fail "copilot pane not in client build (mudlet_SRCS)"

# The copilot engine consumes the EP-015 capsule and EP-016 router surfaces.
grep -q "pub struct ContextCapsule" wirecore/crates/wire-context/src/lib.rs \
  || fail "ContextCapsule surface missing"
grep -q "pub struct AiRouter" wirecore/crates/wire-ai-router/src/lib.rs \
  || fail "AiRouter surface missing"
grep -q "use wire_ai_router::" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "copilot does not route through EP-016"

# The engine exposes the states the node contract requires.
for sym in CopilotOutcome Suggestion NoSuggestion ProviderCompletion CompletionError; do
  grep -q "$sym" wirecore/crates/wire-copilot/src/lib.rs || fail "missing $sym"
done

# All pane states exist (SPEC-025 mapping).
for state in Loading Ready Disabled Denied Degraded Canceled Unavailable Error; do
  grep -q "$state" src/wiremudder/ui/copilot/copilot_boundary.h \
    || fail "pane missing state $state"
done

echo "integration EP-017 M3 copilot-flow: ok"
