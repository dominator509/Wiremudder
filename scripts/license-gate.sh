#!/usr/bin/env sh
set -eu
[ -f licenses/wiremudder/THIRD_PARTY_NOTICES.md ] || { echo 'license gate: FAIL - missing notices' >&2; exit 1; }
[ -f sbom/wiremudder/SBOM.spdx.json ] || { echo 'license gate: FAIL - missing SBOM' >&2; exit 1; }
sh scripts/run-locked-command.sh license
echo 'license gate: ok'
