#!/usr/bin/env sh
# EP-035 M1 contract test: the node verifier exists, is executable, and fails
# closed on unknown subcommands and nonexistent milestones instead of
# printing a false success sentinel.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f scripts/node-verifiers/EP-035.sh ] || fail "missing node verifier"
[ -x scripts/node-verifiers/EP-035.sh ] || fail "node verifier not executable"

# Unknown subcommands must fail closed.
if scripts/node-verifiers/EP-035.sh NO_SUCH_SUBCOMMAND >/dev/null 2>&1; then
  fail "verifier accepted unknown subcommand"
fi

# Nonexistent milestone subcommands must fail closed.
if scripts/node-verifiers/EP-035.sh M99 >/dev/null 2>&1; then
  fail "verifier accepted nonexistent milestone M99"
fi

echo "contract EP-035 verifier-fails-closed: ok"
