#!/usr/bin/env sh
set -eu
sh scripts/verify.sh
python3 scripts/production_readiness.py
[ "${WIREMUDDER_AUTO_DEPLOY:-false}" = false ] || { echo 'production readiness: FAIL - auto deploy must remain false' >&2; exit 1; }
echo 'production readiness: ok'
