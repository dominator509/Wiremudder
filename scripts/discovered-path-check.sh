#!/usr/bin/env sh
set -eu
[ "$#" -eq 1 ] || { echo 'usage: discovered-path-check.sh EP-XXX' >&2; exit 2; }
exec python3 scripts/discovered_path_check.py "$1"
