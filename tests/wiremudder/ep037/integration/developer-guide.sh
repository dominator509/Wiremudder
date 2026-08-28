#!/usr/bin/env sh
# EP-037 M3 integration test: the developer guide documents real locked
# commands and inherited build docs. Verify the referenced paths and locked
# command keys exist exactly as documented.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

[ -f docs/wiremudder/developer/README.md ] || fail "missing developer guide"

# Locked command keys the guide documents.
for key in configure build unit; do
  awk -F'\t' -v k="$key" '$1==k {found=1} END {exit !found}' \
    .agent/state/COMMANDS.lock.tsv || fail "locked command $key missing"
done

# Inherited build docs the guide references.
for f in docs/platform-builds.md CONTRIBUTING.md docs/CONTRIBUTING.md docs/README.md; do
  [ -f "$f" ] || fail "inherited doc $f missing"
done

# The guide's cross-references resolve.
for ref in docs/wiremudder/user/README.md docs/wiremudder/package-author/README.md \
           WIREMUDDER_SECURITY.md; do
  [ -f "$ref" ] || fail "guide reference $ref missing"
done

echo "integration EP-037 developer-guide: ok"
