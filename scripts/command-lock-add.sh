#!/usr/bin/env sh
set -eu
[ "$#" -ge 5 ] || { echo 'usage: command-lock-add.sh KEY EVIDENCE_ID OWNER_NODE PLATFORM COMMAND' >&2; exit 2; }
exec python3 scripts/command_lock_add.py "$@"
