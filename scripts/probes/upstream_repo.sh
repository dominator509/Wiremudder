#!/usr/bin/env sh
set -eu
[ "${WIREMUDDER_UPSTREAM_REPO:-}" = 'https://github.com/Mudlet/Mudlet.git' ] || { echo 'upstream repo probe: mismatch' >&2; exit 1; }
