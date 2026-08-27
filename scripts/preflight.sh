#!/usr/bin/env sh
set -eu
fail(){ echo "preflight: FAIL - $1" >&2; exit 1; }
[ -f AGENTS.md ] && [ -d .agent ] || fail 'run from repository root'
sh scripts/validate-blueprint.sh >/dev/null || fail 'blueprint validation'
for t in git sh awk grep sed python3 cmake; do command -v "$t" >/dev/null 2>&1 || fail "missing tool $t"; done
python3 - <<'PYV' || fail 'CMake 3.25.1 or newer required'
import re, subprocess
out=subprocess.check_output(['cmake','--version'], text=True)
m=re.search(r'(\d+)\.(\d+)\.(\d+)', out)
raise SystemExit(0 if m and tuple(map(int,m.groups())) >= (3,25,1) else 1)
PYV
[ -f .env ] || fail 'copy .env.example to .env and set WIREMUDDER_CMAKE_PRESET'
set -a; . ./.env; set +a
TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
awk '/^PREFLIGHT-TABLE-BEGIN$/{p=1;next} /^PREFLIGHT-TABLE-END$/{p=0} p&&NF' PREFLIGHT.md > "$TMP"
[ -s "$TMP" ] || fail 'empty PREFLIGHT table'
while IFS='|' read -r var req probe; do
  eval "value=\${$var:-}"
  if [ -z "$value" ]; then
    [ "$req" = OPTIONAL ] && { echo "preflight: optional $var disabled"; continue; }
    fail "missing $var"
  fi
  if [ "$probe" != '-' ]; then [ -f "$probe" ] || fail "missing probe $probe"; sh "$probe" || fail "probe failed $var"; fi
done < "$TMP"
sh scripts/upstream-lock-check.sh >/dev/null || fail 'upstream lock'
agent=${WIREMUDDER_AGENT_ID:-local-operator}
sh scripts/ledger.sh append "$agent" - PREFLIGHT_OK 'baseline preflight: ok'
echo 'preflight: ok'
