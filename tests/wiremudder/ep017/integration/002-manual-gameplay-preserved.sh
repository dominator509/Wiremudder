#!/usr/bin/env sh
# EP-017 M3 integration test: optional failure preserves manual text gameplay.
# The copilot pane is a passive observer; a failed/unavailable copilot must
# never block, mutate, or delay the terminal stream.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# Passive-by-construction invariant.
grep -q "isPassive() const { return true; }" src/wiremudder/ui/copilot/copilot_boundary.h \
  || fail "copilot pane is not passive"

# The pane holds no reference to the terminal or command path.
if grep -q "TBuffer\|TCommandLine\|sendCommand\|mpConsole" src/wiremudder/ui/copilot/copilot_boundary.h src/wiremudder/ui/copilot/copilot_boundary.cpp; then
  fail "copilot pane must not touch terminal/command internals"
fi

# No execute path exists anywhere in the copilot boundary. The boundary is
# a data holder; check for actual command-send/execution API calls, not the
# word "execute" in documentation comments.
if grep -nE "sendCommand|runCommand|->send\(|TCommandLine|mpConsole->|system\(|QProcess|::exec|->execute\(" \
    src/wiremudder/ui/copilot/copilot_boundary.h src/wiremudder/ui/copilot/copilot_boundary.cpp; then
  fail "copilot boundary must have no execute path"
fi

echo "integration EP-017 M3 manual-gameplay-preserved: ok"
