#!/usr/bin/env sh
# EP-038 M4 security test: the release candidate and its evidence carry no
# secrets, claim no signing authority, and record honest provenance.
# Redactor discipline: the scan covers only EP-038's own boundaries.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

cand=release/wiremudder/candidate
work=$(mktemp -d /tmp/ep038_sec_XXXX)
trap 'rm -rf "$work"' EXIT

# 1. No secret-material patterns in the candidate artifact set or the
#    release evidence. (sk- is a real redaction pattern; inherited docs
#    outside this node's boundaries are NOT scanned.)
secret_patterns='sk-[A-Za-z0-9]\{20,\}|AKIA[0-9A-Z]\{16\}|ghp_[A-Za-z0-9]\{30,\}|-----BEGIN [A-Z]* PRIVATE KEY-----'
hits=$(grep -rEl "$secret_patterns" "$cand" .agent/state/release-evidence/ 2>/dev/null || true)
[ -z "$hits" ] || fail "secret material found: $hits"

# 2. No .env or token files are part of the candidate.
[ ! -f "$cand/.env" ] || fail ".env must not ship"
[ ! -f "$cand/.env.*" ] || fail "env files must not ship"
for f in $(find "$cand" -name "*.env*" 2>/dev/null); do
  fail "env-like file shipped: $f"
done

# 3. Provenance never claims signing; the manifest records it honestly.
python3 - <<'PY' || fail "provenance must not claim signing"
import json
p = json.load(open('release/wiremudder/candidate/provenance.json'))
assert p['signed_by_maintainer'] is False, "provenance claims signing"
assert p['prepared_by_agent'] is True, "provenance not agent-prepared"
PY
grep -q '"has_signature": false' "$cand/manifest.json" \
  || fail "manifest must record unsigned candidate"

# 4. Provenance fields carry real values, not placeholders.
python3 - <<'PY' || fail "provenance fields are placeholder"
import json
p = json.load(open('release/wiremudder/candidate/provenance.json'))
for k in ('upstream_repository','upstream_commit','source_commit','build_host'):
    assert p.get(k), f"empty provenance field {k}"
PY

# 5. Release claims: every implemented/certified claim has a real evidence
#    path and no out-of-profile feature is claimed (full profile).
WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh >/dev/null \
  || fail "claims gate failed under full profile"

# 6. No credentials in the candidate manifest or checksum files.
grep -qi "password\|api_key\|token\|secret" "$cand/manifest.json" \
  && fail "manifest contains credential-like text" || true
grep -qi "password\|api_key\|token\|secret" "$cand/provenance.json" \
  && fail "provenance contains credential-like text" || true

echo "security EP-038 release-candidate-security: ok"
