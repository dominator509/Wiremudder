#!/usr/bin/env sh
# EP-031 M5 requirement test: WM-SPEC-007-R10 - "Localization follows
# existing Mudlet translation conventions and new strings include
# translator context where needed." The requirement's validation matrix row
# maps it to live-fire LF-031; this test independently verifies the R10
# obligation at the catalog level (5-level depth: spec -> matrix -> owned
# test path -> catalog convention -> real lrelease compile).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "requirements: FAIL - $1" >&2; exit 1; }

# 1. The requirement exists in the owning spec.
grep -q "WM-SPEC-007-R10" .agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md \
  || fail "WM-SPEC-007-R10 missing from SPEC-007"

# 2. The validation matrix maps it to EP-031, live-fire LF-031, and this
#    test path.
grep -q "WM-SPEC-007-R10.*EP-031.*LF-031" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "matrix row for WM-SPEC-007-R10 missing EP-031/LF-031"
grep -q "tests/wiremudder/ep031/requirements/wm-spec-007-r10" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "matrix row for WM-SPEC-007-R10 missing test path"

# 3. The owned test path exists (this file).
[ -f tests/wiremudder/ep031/requirements/wm-spec-007-r10.sh ] \
  || fail "owned requirement test missing"

# 4. The catalog follows the inherited Mudlet convention: TS 2.1, named
#    context, translator comment per message.
ts=translations/wiremudder/wiremudder.ts
[ -f "$ts" ] || fail "missing translations/wiremudder/wiremudder.ts"
grep -q '<TS version="2.1"' "$ts" || fail "catalog is not TS version 2.1"
python3 - "$ts" <<'PY' || fail "translator context check failed"
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
msgs = list(root.iter('message'))
assert len(msgs) >= 10, f"expected >=10 messages, got {len(msgs)}"
for m in msgs:
    assert m.findtext('source'), f"message missing <source>: {m}"
    assert m.findtext('comment'), f"message missing translator <comment>: {m}"
print(f"catalog messages={len(msgs)} all carry source+translator context")
PY

# 5. The real Qt6 lrelease compiles the catalog (inherited convention).
qm=$(mktemp /tmp/ep031_r10_XXXX.qm)
/opt/qt/6.8.2/gcc_64/bin/lrelease "$ts" -compress -qm "$qm" >/tmp/ep031_r10_lrelease.log 2>&1 \
  || { cat /tmp/ep031_r10_lrelease.log >&2; fail "lrelease failed"; }
[ -s "$qm" ] || fail "lrelease produced empty .qm"

# The boundary model requires translator context (R10).
grep -q "bool translatorContextRequired() const { return true; }" \
  src/wiremudder/accessibility/accessibility_boundary.h \
  || fail "boundary does not require translator context"

echo "requirements WM-SPEC-007-R10: ok"
