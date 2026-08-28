#!/usr/bin/env sh
# EP-036 M1 contract test: the certification surfaces this node builds on
# exist and carry the exact anchors the node contract requires — the pinned
# upstream commit, the platform-certification spec, the event-schema spec,
# and the live-fire path.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Provenance anchor (SPEC-001): pinned upstream commit.
[ -f UPSTREAM.lock.yaml ] || fail "missing UPSTREAM.lock.yaml"
grep -q "development_commit" UPSTREAM.lock.yaml || fail "lock missing development_commit"
[ -f .env ] || fail "missing .env"
set -a; . ./.env; set +a
[ -n "${WIREMUDDER_UPSTREAM_COMMIT:-}" ] || fail "pinned commit env missing"
git cat-file -e "${WIREMUDDER_UPSTREAM_COMMIT}^{commit}" 2>/dev/null \
  || fail "pinned commit not present"

# Owning specs exist.
[ -f .agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md ] \
  || fail "missing SPEC-027"
[ -f .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md ] \
  || fail "missing SPEC-019"
[ -f .agent/specs/SPEC-001-upstream-fork-provenance-and-sync.md ] \
  || fail "missing SPEC-001"

# The certification/chaos boundaries are authorized by the contract.
for b in tests/wiremudder/platform/ tests/wiremudder/chaos/ \
         compatibility/platform/ docs/wiremudder/certification/; do
  grep -q "$b" .agent/node-contracts/EP-036.md || fail "boundary $b missing from contract"
done

# The live-fire proof path is contractually fixed.
grep -q "LF-036" .agent/node-contracts/EP-036.md || fail "LF-036 missing from contract"

echo "contract EP-036 certification-surfaces: ok"
