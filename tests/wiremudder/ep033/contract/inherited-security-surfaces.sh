#!/usr/bin/env sh
# EP-033 M1 contract test: the inherited security surfaces this node builds on
# exist and carry the exact anchors the node contract requires — pinned
# upstream provenance, GPL license obligations, submodule inventory, and the
# security policy gate.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# SPEC-001-R03: EP-000 verifies the locked commit and license files before edits.
[ -f UPSTREAM.lock.yaml ] || fail "missing UPSTREAM.lock.yaml"
grep -q "development_commit" UPSTREAM.lock.yaml || fail "UPSTREAM.lock.yaml missing development_commit"

# SPEC-001-R08: submodule and license provenance inventory anchor.
[ -f .gitmodules ] || fail "missing .gitmodules"
grep -q "3rdparty/" .gitmodules || fail "no submodules declared"

# GPL/source obligations anchors.
[ -f COPYING ] || fail "missing COPYING"
grep -q "GNU GENERAL PUBLIC LICENSE" COPYING || fail "COPYING missing GPL text"
[ -f LICENSE_STRATEGY.md ] || fail "missing LICENSE_STRATEGY.md"

# Security policy and gate anchors.
[ -f WIREMUDDER_SECURITY.md ] || fail "missing WIREMUDDER_SECURITY.md"
[ -f scripts/security-check.sh ] || fail "missing security-check.sh"

# The live-fire proof path is contractually fixed.
grep -q "LF-033" .agent/node-contracts/EP-033.md || fail "LF-033 missing from contract"

echo "contract EP-033 inherited-security-surfaces: ok"
