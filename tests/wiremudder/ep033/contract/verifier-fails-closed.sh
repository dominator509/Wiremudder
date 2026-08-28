#!/usr/bin/env sh
# EP-033 M1 contract test: the node verifier exists, is executable, and fails
# closed on unknown subcommands and on missing milestone boundaries instead of
# printing a false success sentinel. (Do not invoke the full verify subcommand
# here: it re-runs M1, which re-runs this test, causing recursion.)
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f scripts/node-verifiers/EP-033.sh ] || fail "missing node verifier"
[ -x scripts/node-verifiers/EP-033.sh ] || fail "node verifier not executable"

# Unknown subcommands must fail closed.
if scripts/node-verifiers/EP-033.sh NO_SUCH_SUBCOMMAND >/dev/null 2>&1; then
  fail "verifier accepted unknown subcommand"
fi

# M2..M5 subcommands must fail closed while their boundaries are absent.
for m in M2 M3 M4 M5; do
  if scripts/node-verifiers/EP-033.sh "$m" >/dev/null 2>&1; then
    fail "subcommand $m passed before its boundary existed"
  fi
done

echo "contract EP-033 verifier-fails-closed: ok"
