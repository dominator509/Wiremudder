#!/usr/bin/env sh
# EP-033 M1 contract test: the node verifier exists, is executable, and fails
# closed on unknown subcommands and nonexistent milestones instead of
# printing a false success sentinel. (Do not assert that M2..M5 fail: once
# the node is implemented their boundaries exist and they legitimately pass.
# The invariant fail-closed surface is unknown input and absent artifacts.)
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f scripts/node-verifiers/EP-033.sh ] || fail "missing node verifier"
[ -x scripts/node-verifiers/EP-033.sh ] || fail "node verifier not executable"

# Unknown subcommands must fail closed.
if scripts/node-verifiers/EP-033.sh NO_SUCH_SUBCOMMAND >/dev/null 2>&1; then
  fail "verifier accepted unknown subcommand"
fi

# Nonexistent milestone subcommands must fail closed.
if scripts/node-verifiers/EP-033.sh M99 >/dev/null 2>&1; then
  fail "verifier accepted nonexistent milestone M99"
fi

echo "contract EP-033 verifier-fails-closed: ok"
