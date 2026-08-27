#!/usr/bin/env sh
# Contract test: pinned upstream commit must exist and be an ancestor of HEAD.
set -eu
. ./.env
git cat-file -e "${WIREMUDDER_UPSTREAM_COMMIT}^{commit}" 2>/dev/null || { echo "FAIL: pinned commit ${WIREMUDDER_UPSTREAM_COMMIT} not present" >&2; exit 1; }
git merge-base --is-ancestor "$WIREMUDDER_UPSTREAM_COMMIT" HEAD || { echo "FAIL: pinned commit is not an ancestor of HEAD" >&2; exit 1; }
echo "contract pinned-commit: ok"
