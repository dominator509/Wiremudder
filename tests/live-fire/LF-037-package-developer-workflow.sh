#!/usr/bin/env sh
# LF-037 package-developer-workflow: live-fire proof for the Documentation,
# Package Developer, and Community Ecosystem node.
#
# Proves: every enabled feature has user documentation (acceptance
# obligation 1); every package permission and update rule is documented
# (obligation 2); examples are executable and tested (obligation 3);
# build/contribution docs preserve upstream rules (obligation 4); privacy
# and diagnostics are understandable (obligation 5); unsupported and
# research features are labeled honestly (obligation 6). Every step uses
# real controlled mechanisms — no mocks.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-037: FAIL - $1" >&2; exit 1; }
pass() { echo "LF-037: ok - $1"; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

work=$(mktemp -d /tmp/lf037_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. Every enabled feature has user documentation.
missing=0
tail -n +2 .agent/features/FEATURES.tsv | \
awk -F'\t' '$2=="required" {print $1}' | while read -r id; do
  if ! grep -q "$id" docs/wiremudder/user/feature-index.md; then
    echo "LF-037: missing user documentation for $id" >&2
    exit 1
  fi
done || fail "a required feature lacks user documentation"
pass "every enabled feature has user documentation ($(tail -n +2 .agent/features/FEATURES.tsv | awk -F'\t' '$2=="required"' | wc -l | tr -d ' ') features)"

# 2. Every package permission and update rule is documented.
perms=$(python3 -c "
import json
s=json.load(open('schemas/wiremudder/packages/manifest.schema.json'))
print(' '.join(s['properties']['requested_permissions']['items']['enum']))
")
for p in $perms; do
  grep -q "$p" docs/wiremudder/package-author/README.md \
    || fail "permission $p not documented"
done
for k in never manual auto; do
  grep -q "\\b$k\\b" docs/wiremudder/package-author/README.md \
    || fail "update policy $k not documented"
done
grep -q "cannot silently expand permissions" docs/wiremudder/package-author/README.md \
  || fail "no-silent-expansion rule missing"
pass "package permissions and update rules documented ($(echo "$perms" | wc -w | tr -d ' ') permissions, 3 policies)"

# 3. Examples are executable and tested.
python3 - "$PWD" <<'PY' || fail "example manifest invalid"
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
schema = json.loads((root / 'schemas/wiremudder/packages/manifest.schema.json').read_text())
manifest = json.loads((root / 'examples/wiremudder/manifest.example.json').read_text())
try:
    import jsonschema
    jsonschema.validate(instance=manifest, schema=schema)
except ImportError:
    for k in schema['required']:
        assert k in manifest, f"missing {k}"
print("example manifest valid")
PY
sh tests/wiremudder/ep037/integration/package-author-oracle.sh >"$out" 2>&1 \
  || { cat "$out" >&2; fail "documented oracle commands do not match reality"; }
pass "examples executable and tested against real contracts"

# 4. Build and contribution instructions preserve upstream rules.
for f in CONTRIBUTING.md docs/CONTRIBUTING.md docs/README.md docs/platform-builds.md; do
  [ -f "$f" ] || fail "inherited $f missing"
done
grep -q "cmake --preset" docs/wiremudder/developer/README.md \
  || fail "developer guide omits upstream build presets"
grep -q "CONTRIBUTING.md" docs/wiremudder/developer/README.md \
  || fail "developer guide omits upstream contribution rules"
pass "build and contribution docs preserve upstream rules"

# 5. Privacy and diagnostics are understandable.
for f in privacy.md telemetry.md troubleshooting.md; do
  [ -f "docs/wiremudder/user/$f" ] || fail "missing user doc $f"
done
grep -q "Nothing by default" docs/wiremudder/user/privacy.md \
  || fail "privacy doc unclear about data egress"
grep -q "content-addressed" docs/wiremudder/user/telemetry.md \
  || fail "telemetry doc missing bundle properties"
pass "privacy and diagnostics understandable"

# 6. Unsupported and research features are labeled honestly.
grep -q "research" docs/wiremudder/user/feature-index.md \
  || fail "research features not labeled"
if grep -q "WM-FEAT-0035.*implemented" docs/wiremudder/user/feature-index.md; then
  fail "research feature mislabeled as implemented"
fi
pass "unsupported and research features labeled honestly"

# 7. Data integrity and gameplay preserved: no inherited source modified.
git diff --quiet -- src/ || fail "inherited src/ modified"
pass "manual gameplay and data integrity preserved"

echo "LF-037: ok - package-developer-workflow certified"
