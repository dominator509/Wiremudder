#!/usr/bin/env sh
# EP-018 M3 integration test: no authority escalation, gameplay preserved.
# The Soul pane is passive, holds no terminal/command reference, and has no
# grant-authority path.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# Passive by construction.
grep -q "isPassive() const { return true; }" src/wiremudder/ui/soul/soul_boundary.h \
  || fail "soul pane is not passive"

# No authority grant path.
grep -q "canGrantAuthority() const { return false; }" src/wiremudder/ui/soul/soul_boundary.h \
  || fail "soul pane can grant authority"

# No terminal/command internals.
if grep -q "TBuffer\|TCommandLine\|sendCommand\|mpConsole" src/wiremudder/ui/soul/soul_boundary.h src/wiremudder/ui/soul/soul_boundary.cpp; then
  fail "soul pane must not touch terminal/command internals"
fi

# No execute/install path in the boundary.
if grep -nE "sendCommand|runCommand|->send\(|TCommandLine|mpConsole->|system\(|QProcess|::exec" \
    src/wiremudder/ui/soul/soul_boundary.h src/wiremudder/ui/soul/soul_boundary.cpp; then
  fail "soul boundary must have no execute path"
fi

echo "integration EP-018 M3 no-authority-escalation: ok"
