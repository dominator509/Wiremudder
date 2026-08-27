#!/usr/bin/env sh
set -eu
[ "$#" -eq 1 ] || { echo 'usage: scope-audit.sh EP-XXX' >&2; exit 2; }
exec python3 scripts/scope_audit.py "$1"
