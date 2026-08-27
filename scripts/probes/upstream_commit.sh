#!/usr/bin/env sh
set -eu
git cat-file -e "${WIREMUDDER_UPSTREAM_COMMIT:?}^{commit}" 2>/dev/null
git merge-base --is-ancestor "$WIREMUDDER_UPSTREAM_COMMIT" HEAD
