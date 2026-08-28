#!/usr/bin/env sh
# EP-031 M3 integration test: the WireMudder translation catalog must
# follow the inherited Mudlet translation build convention end to end:
# lrelease compiles the master .ts to a real .qm (same -compress flags the
# inherited build uses), and the catalog carries translator context for
# every new string (WM-SPEC-007-R10).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

ts=translations/wiremudder/wiremudder.ts
[ -f "$ts" ] || fail "missing $ts"

qm=$(mktemp /tmp/ep031_wiremudder_XXXX.qm)
/opt/qt/6.8.2/gcc_64/bin/lrelease "$ts" -compress -qm "$qm" >/tmp/ep031_lrelease.log 2>&1 \
  || { cat /tmp/ep031_lrelease.log >&2; fail "lrelease failed"; }
[ -s "$qm" ] || fail "lrelease produced empty .qm"

# The compiled catalog is a real Qt resource (QM sentry magic 0x3C 0xB8).
python3 - "$qm" <<'PY' || fail "compiled catalog magic check failed"
import sys
with open(sys.argv[1], 'rb') as f:
    head = f.read(16)
# Qt .qm files begin with the sentry 0x3C 0xB8 (value 15544)
assert head[:2] == b'\x3c\xb8', f"unexpected .qm magic {head[:2]!r}"
print("qm magic ok")
PY

# Every new string has translator context (WM-SPEC-007-R10).
python3 - "$ts" <<'PY' || fail "translator context check failed"
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
msgs = list(root.iter('message'))
assert len(msgs) >= 10, f"expected >=10 messages, got {len(msgs)}"
for m in msgs:
    assert m.findtext('comment'), f"message missing translator <comment>: {m}"
print(f"catalog messages={len(msgs)} all carry translator context")
PY

echo "integration EP-031 translation-build: ok"
