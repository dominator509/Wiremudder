#!/usr/bin/env sh
# Contract test: the pinned upstream history is preserved (no rebase/
# rewrite of the Mudlet foundation).
set -eu
. ./.env
commit=$WIREMUDDER_UPSTREAM_COMMIT
git cat-file -e "$commit^{commit}" || { echo "FAIL: pinned commit missing" >&2; exit 1; }
git merge-base --is-ancestor "$commit" HEAD || { echo "FAIL: pinned commit not ancestor" >&2; exit 1; }
# The pinned commit's tree must still exist in history (nothing rewritten).
git rev-list --count "$commit" >/dev/null 2>&1 || { echo "FAIL: history rewritten" >&2; exit 1; }
echo "contract history-preserved: ok"
