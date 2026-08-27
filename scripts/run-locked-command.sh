#!/usr/bin/env sh
set -eu
[ "$#" -eq 1 ] || { echo 'usage: run-locked-command.sh KEY' >&2; exit 2; }
exec python3 scripts/run_locked_command.py "$1"
