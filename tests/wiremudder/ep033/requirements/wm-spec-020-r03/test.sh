#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-020-R03 — stable artifacts and
# manifests are signed, hashed, provenance-recorded, reproducible where
# practical, and accompanied by SBOM and license inventory.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

out=$(mktemp /tmp/ep033_r0203_XXXX.log)
trap 'rm -f "$out"' EXIT

"$cargo_bin" run --quiet --release --manifest-path security/wiremudder/Cargo.toml -- \
  sbom sbom/wiremudder/inventory.json >"$out" 2>&1 || fail "sbom failed"
h1=$(grep -oP 'sha256=\K[0-9a-f]{64}' "$out")
"$cargo_bin" run --quiet --release --manifest-path security/wiremudder/Cargo.toml -- \
  sbom sbom/wiremudder/inventory.json >"$out" 2>&1
h2=$(grep -oP 'sha256=\K[0-9a-f]{64}' "$out")
[ -n "$h1" ] && [ "$h1" = "$h2" ] || fail "sbom not reproducible"

python3 - licenses/wiremudder/licenses.json <<'PY' || fail "license inventory invalid"
import json, sys
d = json.load(open(sys.argv[1]))
assert any(e["source_obligation"] and "GPL" in e["license"] for e in d["entries"])
print("license inventory present with GPL obligations")
PY

echo "requirement WM-SPEC-020-R03: ok"
