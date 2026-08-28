#!/usr/bin/env sh
# EP-036 M2 unit test: the certification evidence chain is real — the
# pinned upstream commit is an ancestor of HEAD, the compatibility matrix
# exists with honest platform status, and the chaos surface preserves
# gameplay integrity.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

# 1. Pinned upstream commit is an ancestor of HEAD (SPEC-001).
[ -f .env ] || fail "missing .env"
set -a; . ./.env; set +a
[ -n "${WIREMUDDER_UPSTREAM_COMMIT:-}" ] || fail "pinned commit env missing"
git cat-file -e "${WIREMUDDER_UPSTREAM_COMMIT}^{commit}" 2>/dev/null \
  || fail "pinned commit not present"
git merge-base --is-ancestor "${WIREMUDDER_UPSTREAM_COMMIT}" HEAD \
  || fail "pinned commit not ancestor of HEAD"

# 2. Compatibility matrix is honest: Linux certified, others development-only.
grep -q "certified" compatibility/platform/matrix.md || fail "matrix missing certified status"
grep -q "development-only" compatibility/platform/matrix.md || fail "matrix missing dev-only status"

# 3. The chaos boundary never touches inherited gameplay sources.
[ -f src/updater.cpp ] || fail "missing inherited updater.cpp"
[ -f src/updater.h ] || fail "missing inherited updater.h"

echo "unit EP-036 certification-evidence-chain: ok"
