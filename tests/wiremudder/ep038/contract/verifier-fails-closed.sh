#!/usr/bin/env sh
# EP-038 M1 contract test: the node verifier exists, is executable, and
# fails closed on unknown subcommands and nonexistent milestones.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f scripts/node-verifiers/EP-038.sh ] || fail "missing node verifier"
[ -x scripts/node-verifiers/EP-038.sh ] || fail "node verifier not executable"

if scripts/node-verifiers/EP-038.sh NO_SUCH_SUBCOMMAND >/dev/null 2>&1; then
  fail "verifier accepted unknown subcommand"
fi

if scripts/node-verifiers/EP-038.sh M99 >/dev/null 2>&1; then
  fail "verifier accepted nonexistent milestone M99"
fi

echo "contract EP-038 verifier-fails-closed: ok"
