#!/usr/bin/env sh
# EP-033 M3 integration test: the security core integrates with the real
# repository — the committed SBOM inventory matches the actual .gitmodules
# submodule set, the SBOM artifact is valid and reproducible, the license
# inventory carries the GPL obligations, and the shared repo secrets gate
# passes.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. The SBOM inventory is generated from the real submodule table.
gitmodules=$(git submodule status 2>/dev/null | wc -l)
[ "$gitmodules" -ge 5 ] || fail "expected >=5 real submodules, got $gitmodules"

python3 - tests/wiremudder/ep033/fixtures/inventory.json sbom/wiremudder/inventory.json <<'PY' || fail "inventory anchor mismatch"
import json, sys
real = json.load(open(sys.argv[2]))
components = real["components"]
kinds = {c["kind"] for c in components}
assert "Source" in kinds and "Submodule" in kinds and "Dependency" in kinds, kinds
assert all(c["license_ok"] for c in components), "license gate must pass on real inventory"
subs = [c["name"] for c in components if c["kind"] == "Submodule"]
assert "3rdparty/edbee-lib" in subs, "real submodule missing from inventory"
print(f"real inventory: {len(components)} components, {len(subs)} submodules")
PY

# 2. The SBOM artifact is valid JSON with a document hash and all entries
#    license-carrying.
python3 - sbom/wiremudder/sbom.json <<'PY' || fail "SBOM artifact invalid"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["spec"] == "wiremudder-sbom-1", d.get("spec")
assert len(d["document_sha256"]) == 64, "document hash missing"
assert len(d["entries"]) >= 8, "expected >=8 entries"
assert all(e["license"] for e in d["entries"]), "entry missing license"
assert all(len(e["sha256"]) == 64 for e in d["entries"]), "entry missing hash"
print(f"SBOM artifact: {len(d['entries'])} entries, hash={d['document_sha256'][:16]}…")
PY

# 3. The license inventory records the GPL source obligations.
python3 - licenses/wiremudder/licenses.json <<'PY' || fail "license inventory invalid"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["entries"], "empty license inventory"
obligations = [e for e in d["entries"] if e["source_obligation"]]
assert any("GPL" in e["license"] for e in obligations), "GPL obligation missing"
print(f"license inventory: {len(d['entries'])} entries, {len(obligations)} source obligations")
PY

# 4. The shared repo secrets gate passes against the tracked tree.
sh tests/wiremudder/security/001-repo-secrets-gate.sh >/dev/null 2>&1 \
  || fail "shared repo secrets gate failed"

echo "integration EP-033 real-repo-security: ok"
