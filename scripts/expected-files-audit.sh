#!/usr/bin/env sh
set -eu
[ "$#" -eq 1 ] || { echo 'usage: expected-files-audit.sh EP-XXX' >&2; exit 2; }
exec python3 scripts/expected_files_audit.py "$1"
