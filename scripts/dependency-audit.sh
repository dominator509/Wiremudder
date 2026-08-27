#!/usr/bin/env sh
set -eu
sh scripts/run-locked-command.sh dependency_audit
[ -f sbom/wiremudder/SBOM.spdx.json ] || { echo 'dependency audit: FAIL - missing SBOM' >&2; exit 1; }
[ -f licenses/wiremudder/THIRD_PARTY_NOTICES.md ] || { echo 'dependency audit: FAIL - missing third-party notices' >&2; exit 1; }
echo 'dependency audit: ok'
