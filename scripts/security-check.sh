#!/usr/bin/env sh
set -eu
sh scripts/validate-blueprint.sh >/dev/null
# Reject obvious committed secret material while avoiding matching documentation examples.
if git grep -nE '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{32,})' -- ':!docs/**' ':!.agent/**' ':!scripts/**' 2>/dev/null; then
  echo 'security check: FAIL - possible secret material' >&2; exit 1
fi
sh scripts/run-locked-command.sh security
echo 'security check: ok'
