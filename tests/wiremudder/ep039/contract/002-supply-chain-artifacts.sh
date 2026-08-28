#!/usr/bin/env sh
# EP-039 M1 contract: the three ship-gate supply-chain artifacts required by
# the run-level gates must exist and be structurally valid (JSON parses,
# notices non-empty, index lists the release candidate artifacts).
set -eu

fail() { echo "ep039 contract: FAIL - $1" >&2; exit 1; }

[ -f sbom/wiremudder/SBOM.spdx.json ] || fail "SBOM.spdx.json missing"
python3 -c "import json; json.load(open('sbom/wiremudder/SBOM.spdx.json'))" \
  || fail "SBOM.spdx.json is not valid JSON"
grep -q "spdxVersion" sbom/wiremudder/SBOM.spdx.json \
  || fail "SBOM.spdx.json missing spdxVersion"

[ -f licenses/wiremudder/THIRD_PARTY_NOTICES.md ] || fail "THIRD_PARTY_NOTICES.md missing"
grep -q "GPL-2.0-or-later" licenses/wiremudder/THIRD_PARTY_NOTICES.md \
  || fail "THIRD_PARTY_NOTICES.md missing core license"

[ -f release/wiremudder/candidate/EVIDENCE_INDEX.json ] || fail "EVIDENCE_INDEX.json missing"
python3 -c "import json; d=json.load(open('release/wiremudder/candidate/EVIDENCE_INDEX.json')); assert d['entries']" \
  || fail "EVIDENCE_INDEX.json empty or invalid"
grep -q "0.9.0-rc1" release/wiremudder/candidate/EVIDENCE_INDEX.json \
  || fail "EVIDENCE_INDEX.json missing release candidate version"

echo "ep039 contract supply-chain-artifacts: ok"
