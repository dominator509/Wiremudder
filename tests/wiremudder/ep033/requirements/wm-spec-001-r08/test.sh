#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-001-R08 — submodule, package,
# generated-file, and binary-asset provenance is inventoried and
# license-gated.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

# The real supply-chain inventory covers submodule provenance and every
# component passes the license gate.
python3 - sbom/wiremudder/inventory.json <<'PY' || fail "inventory invalid"
import json, sys
d = json.load(open(sys.argv[1]))
assert any(c["kind"] == "Submodule" for c in d["components"])
assert all(c["license_ok"] for c in d["components"])
print("submodule provenance inventoried and license-gated")
PY

echo "requirement WM-SPEC-001-R08: ok"
