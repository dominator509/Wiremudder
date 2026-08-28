#!/usr/bin/env sh
# EP-033 M4 security test: supply-chain scan (SPEC-022-R06, SPEC-001-R08,
# SPEC-020-R03).
#
# Supply-chain review covers source, dependency, submodule, binary, model,
# voice, audio, visual, package, installer, and update provenance. The real
# inventory is license-gated, the SBOM is reproducible, and update lanes are
# separate and optional-by-default.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"
run_cli() {
  "$cargo_bin" run --quiet --release --manifest-path security/wiremudder/Cargo.toml -- "$@"
}

out=$(mktemp /tmp/ep033_sc_XXXX.log)
trap 'rm -f "$out"' EXIT

# 1. Real inventory covers the required provenance kinds (SPEC-022-R06).
python3 - sbom/wiremudder/inventory.json <<'PY' || fail "inventory kind coverage"
import json, sys
d = json.load(open(sys.argv[1]))
kinds = {c["kind"] for c in d["components"]}
for k in ["Source", "Dependency", "Submodule"]:
    assert k in kinds, f"missing provenance kind {k}"
print("inventory covers source, dependency, submodule provenance")
PY

# 2. SBOM reproducible (SPEC-020-R03).
run_cli sbom sbom/wiremudder/inventory.json >"$out" 2>&1 || fail "sbom run failed"
hash1=$(grep -oP 'sha256=\K[0-9a-f]{64}' "$out")
run_cli sbom sbom/wiremudder/inventory.json >"$out" 2>&1
hash2=$(grep -oP 'sha256=\K[0-9a-f]{64}' "$out")
[ -n "$hash1" ] && [ "$hash1" = "$hash2" ] || fail "sbom not reproducible"

# 3. Nine separate update lanes, optional assets disabled by default
#    (SPEC-020-R02, SPEC-020-R08).
run_cli lanes >"$out" 2>&1 || fail "lanes failed"
lanes=$(grep -c '^lane ' "$out")
[ "$lanes" -eq 9 ] || fail "expected 9 lanes, got $lanes"
enabled_optional=$(grep -c 'optional=true enabled=true' "$out" || true)
[ "$enabled_optional" -eq 0 ] || fail "optional lane silently enabled"

echo "security EP-033 supply-chain-scan: ok"
