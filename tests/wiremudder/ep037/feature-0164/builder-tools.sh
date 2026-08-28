#!/usr/bin/env sh
# EP-037 M5 feature test WM-FEAT-0164: builder tools are documented with
# evidence, safety, rollback, and release-profile controls. The docs must
# describe the real package builder surface and the safety gates.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0164: FAIL - $1" >&2; exit 1; }

# The builder-tools surface is documented in the package-author and
# developer guides.
grep -q "manifest" docs/wiremudder/package-author/README.md \
  || fail "manifest format not documented"
grep -q "content_sha256" docs/wiremudder/package-author/README.md \
  || fail "content hash requirement not documented"
grep -q "wire-packages-oracle" docs/wiremudder/package-author/README.md \
  || fail "builder oracle not documented"

# Evidence: the example manifest is real and valid.
python3 - "$PWD" <<'PY' || fail "example manifest invalid"
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
schema = json.loads((root / 'schemas/wiremudder/packages/manifest.schema.json').read_text())
manifest = json.loads((root / 'examples/wiremudder/manifest.example.json').read_text())
for k in schema['required']:
    assert k in manifest, f"missing {k}"
print("builder example valid")
PY

# Safety: default-deny and no-silent-expansion are documented.
grep -q "default.*deny\|default is.*deny" docs/wiremudder/package-author/README.md \
  || fail "default-deny not documented"
grep -q "cannot silently expand permissions" docs/wiremudder/package-author/README.md \
  || fail "no-silent-expansion not documented"

# Rollback: builder changes are reversible.
grep -qi "rollback" docs/wiremudder/package-author/README.md \
  || fail "rollback not documented"

# Release-profile controls: docs label what is certified.
grep -q "certified\|research" docs/wiremudder/user/feature-index.md \
  || fail "release-profile labels missing"

echo "feature-0164 EP-037 builder-tools: ok"
