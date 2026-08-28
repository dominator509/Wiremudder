#!/usr/bin/env sh
# EP-031 M2 unit test: the WireMudder translation catalog must follow the
# inherited Mudlet translation convention exactly (WM-SPEC-007-R10):
# TS version 2.1, named context, <source> + translator <comment> for every
# message, and the real Qt6 lrelease must compile it to a .qm with the
# same -compress flags the inherited build uses.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

ts=translations/wiremudder/wiremudder.ts
[ -f "$ts" ] || fail "missing $ts"

# TS version 2.1 (the inherited mudlet.ts uses the same).
grep -q '<TS version="2.1"' "$ts" || fail "catalog is not TS version 2.1"

# Named context exists.
grep -q '<name>WireMudderAccessibility</name>' "$ts" || fail "missing catalog context name"

# Every message has a source and translator comment (context).
python3 - "$ts" <<'PY' || fail "catalog invariant check failed"
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
msgs = list(root.iter('message'))
assert len(msgs) >= 10, f"expected >=10 messages, got {len(msgs)}"
for m in msgs:
    assert m.findtext('source'), f"message missing <source>: {m}"
    assert m.findtext('comment'), f"message missing translator <comment>: {m}"
print(f"catalog messages={len(msgs)} all have source+context")
PY

# The real Qt6 lrelease compiles it (same flags as the inherited build:
# translations/translated/CMakeLists.txt uses -compress -qm).
qm=$(mktemp /tmp/ep031_wiremudder_XXXX.qm)
/opt/qt/6.8.2/gcc_64/bin/lrelease "$ts" -compress -qm "$qm" >/tmp/ep031_lrelease.log 2>&1 \
  || { cat /tmp/ep031_lrelease.log >&2; fail "lrelease failed"; }
[ -s "$qm" ] || fail "lrelease produced empty .qm"

echo "unit translation-catalog: ok"
