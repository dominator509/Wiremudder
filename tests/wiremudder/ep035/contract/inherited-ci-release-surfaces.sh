#!/usr/bin/env sh
# EP-035 M1 contract test: the inherited CI/release surfaces this node
# adapts exist and carry the exact anchors the node contract requires —
# the create-release workflow gated on successful builds, the build
# workflows, the dblsqd PTB channel link, and the upstream provenance lock.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Inherited CI surface (never invented).
[ -f .github/workflows/create-github-release.yml ] || fail "missing create-github-release.yml"
grep -q "workflow_run" .github/workflows/create-github-release.yml \
  || fail "create-release missing workflow_run gate"
grep -q "conclusion == 'success'" .github/workflows/create-github-release.yml \
  || fail "create-release missing success gate"
[ -f .github/workflows/build-mudlet.yml ] || fail "missing build-mudlet.yml"
[ -f .github/workflows/build-mudlet-win.yml ] || fail "missing build-mudlet-win.yml"
[ -f .github/workflows/link-ptbs-to-dblsqd.yml ] || fail "missing link-ptbs-to-dblsqd.yml"

# Channel mechanism consumed by the updater (EP-034 dependency).
grep -q "dblsqd" .github/workflows/link-ptbs-to-dblsqd.yml \
  || fail "dblsqd channel link missing"

# Provenance lock (SPEC-001).
[ -f UPSTREAM.lock.yaml ] || fail "missing UPSTREAM.lock.yaml"
grep -q "development_commit" UPSTREAM.lock.yaml || fail "UPSTREAM.lock.yaml missing development_commit"

# Release-candidate storage is optional; stable publication remains manual.
[ -f .agent/preflight/EP-035-release-storage.env.example ] || fail "missing release-storage env example"
grep -q "WIREMUDDER_RC_ARTIFACT" .agent/preflight/EP-035-release-storage.env.example \
  || fail "release-storage env missing artifact vars"

# The live-fire proof path is contractually fixed.
grep -q "LF-035" .agent/node-contracts/EP-035.md || fail "LF-035 missing from contract"

echo "contract EP-035 inherited-ci-release-surfaces: ok"
