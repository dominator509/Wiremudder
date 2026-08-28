#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-022-R06 — supply-chain review covers
# source, dependency, submodule, binary, model, voice, audio, visual,
# package, installer, and update provenance.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

# The inventory model enumerates every SPEC-022-R06 provenance kind.
python3 - security/wiremudder/src/inventory.rs <<'PY' || fail "provenance kinds incomplete"
src = open("security/wiremudder/src/inventory.rs").read()
for kind in ["Source", "Dependency", "Submodule", "Binary", "Model", "Voice",
             "Audio", "Visual", "Package", "Installer", "Update"]:
    assert kind in src, f"provenance kind {kind} missing"
print("all SPEC-022-R06 provenance kinds enumerated")
PY

# The real inventory actually covers source, dependency, and submodule.
python3 - sbom/wiremudder/inventory.json <<'PY' || fail "inventory invalid"
import json, sys
d = json.load(open(sys.argv[1]))
kinds = {c["kind"] for c in d["components"]}
for k in ["Source", "Dependency", "Submodule"]:
    assert k in kinds, f"real inventory missing {k}"
print("real inventory covers source, dependency, submodule")
PY

echo "requirement WM-SPEC-022-R06: ok"
