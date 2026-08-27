#!/usr/bin/env sh
set -eu
[ "$#" -eq 6 ] || { echo 'usage: discovered-path-add.sh EP-XXX EVIDENCE_ID PATH RATIONALE TEST_PATH ROLLBACK' >&2; exit 2; }
exec python3 scripts/discovered_path_add.py "$@"
