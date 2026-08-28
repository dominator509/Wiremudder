#!/usr/bin/env sh
# WM-SPEC-014-R01: Player Copilot observes approved context and produces
# suggestions, explanations, citations, uncertainty, and optional Action
# Proposals without hidden command send.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r01: FAIL - $1" >&2; exit 1; }

# Approved-context rule: the engine builds routing inputs from the capsule,
# never from raw transcripts.
grep -q "fn routing_inputs" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "approved-context routing missing"
grep -q "build_task_summary" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "task summary missing"

# Suggestions carry explanations, citations, uncertainty, and optional
# Action Proposals.
grep -q "pub struct Suggestion" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "Suggestion missing"
grep -q "pub citations" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "citations missing"
grep -q "pub uncertainty" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "uncertainty missing"
grep -q "pub action_proposal" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "action proposal missing"

# No hidden command send: the engine and pane have no execute path.
if grep -nE "sendCommand|runCommand|->send\(|TCommandLine|mpConsole->|system\(|QProcess|::exec" \
    src/wiremudder/ui/copilot/copilot_boundary.h src/wiremudder/ui/copilot/copilot_boundary.cpp; then
  fail "copilot boundary has an execute path"
fi

echo "req WM-SPEC-014-R01: ok"
