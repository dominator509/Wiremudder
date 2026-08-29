# WM-SPEC-028-R06: Production is not automatically deployed or published
# because AUTO_DEPLOY is false; the pack emits exact manual signing and
# publish steps without exposing keys.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "wm-spec-028-r06: FAIL - $1" >&2; exit 1; }

# 1. AUTO_DEPLOY=false at the three real layers the release reads.
[ -f .env ] && { set -a; . ./.env; set +a; }
[ "${WIREMUDDER_AUTO_DEPLOY:-}" = "false" ] || fail "WIREMUDDER_AUTO_DEPLOY not false (.env)"
sh scripts/probes/auto_deploy.sh >/dev/null 2>&1 || fail "auto_deploy probe did not confirm false"
python3 -c "
import json,sys
m=json.load(open('release/wiremudder/final/manifest.json'))
assert m.get('auto_deploy') is False, 'manifest auto_deploy not false'
" || fail "manifest auto_deploy not false"

# 2. The manual signing/publish packet exists, contains exact steps, and
#    never exposes signing keys or secrets.
packet=docs/wiremudder/ship/MANUAL_PUBLISH_PACKET.md
[ -f "$packet" ] || fail "manual publish packet missing"
grep -qi "sign" "$packet" || fail "packet lacks signing steps"
grep -qi "publish" "$packet" || fail "packet lacks publish steps"
if grep -qiE "BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|sk-[A-Za-z0-9]{20}|ghp_[A-Za-z0-9]{20}|AKIA[0-9A-Z]{16}|api[_-]?key[[:space:]]*=[[:space:]]*['\"]?[A-Za-z0-9]{16}" "$packet"; then
  fail "packet exposes key material"
fi

# 3. No signature material exists in the release boundary (agent never signs).
if find release/wiremudder -name '*.sig' -o -name '*.asc' -o -name '*.gpg' 2>/dev/null | grep -q .; then
  fail "signature material present in release boundary"
fi
python3 -c "
import json
m=json.load(open('release/wiremudder/final/manifest.json'))
assert m.get('has_signature') is False, 'manifest claims a signature'
p=json.load(open('release/wiremudder/final/provenance.json'))
assert p.get('signed_by_maintainer') is False, 'provenance claims maintainer signature'
" || fail "release boundary claims a signature"

echo "wm-spec-028-r06: ok"
