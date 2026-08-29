#!/usr/bin/env sh
# LF-039 ship-gate: live-fire proof for Production Readiness, Ship, and
# Run Complete (EP-039, WM-SPEC-028-R06/R10).
#
# The final release boundary is proven end to end with real artifacts:
# all 39 graph nodes DONE with green tags, production readiness structural
# check, evidence corpus hash, release claims gate, oracle stable-refusal of
# the unsigned boundary, manual publish packet without key exposure, and
# AUTO_DEPLOY=false. No mocks — every assertion runs real bytes and the real
# oracle.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-039: FAIL - $1" >&2; exit 1; }
pass() { echo "LF-039: ok - $1"; }

oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || fail "oracle binary missing (build packaging/wiremudder release first)"

work=$(mktemp -d /tmp/lf039_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. Production readiness structural check (EP-000..EP-038 DONE+green).
python3 scripts/production_readiness.py >"$out" 2>&1 \
  || fail "production readiness: $(cat "$out")"
grep -q "production readiness structural: ok" "$out" || fail "readiness sentinel"
pass "production readiness structural ok (prior 39 nodes)"

# 2. Ledger lifecycle: at least 39 NODE_DONE rows and a green tag each.
done_count=$(grep -c '| NODE_DONE |' .agent/state/LEDGER.md || true)
[ "$done_count" -ge 39 ] || fail "NODE_DONE rows: $done_count < 39"
for node in $(grep '| NODE_DONE |' .agent/state/LEDGER.md | awk -F'|' '{gsub(/ /,"",$3); print $3}'); do
  git rev-parse -q --verify "refs/tags/green/$node" >/dev/null \
    || fail "missing green/$node"
done
pass "ledger lifecycle: $done_count NODE_DONE rows, all green tags"

# 3. Evidence corpus aggregate matches the final-evidence index and the
#    candidate EVIDENCE_INDEX records the same corpus hash.
corpus=.agent/state/final-evidence/evidence-corpus.sha256
[ -f "$corpus" ] || fail "evidence corpus hash missing"
[ -f .agent/state/final-evidence/index.json ] || fail "evidence index missing"
recorded=$(python3 -c "import json;print(json.load(open('release/wiremudder/candidate/EVIDENCE_INDEX.json'))['evidence_corpus']['corpus_sha256'])")
actual=$(awk '{print $1}' "$corpus")
[ "$recorded" = "$actual" ] || fail "corpus hash mismatch: recorded=$recorded actual=$actual"
pass "evidence corpus hash matches candidate EVIDENCE_INDEX ($actual)"

# 4. Final boundary is honest and unsigned (SPEC-020-R09, SPEC-028-R05).
python3 - <<'PY' || fail "final boundary dishonesty"
import json
m = json.load(open('release/wiremudder/final/manifest.json'))
assert m['has_signature'] is False
assert m['auto_deploy'] is False
for k in ('has_source_archive','has_binary','has_checksums','has_sbom',
          'has_provenance','has_license_notices','has_release_notes',
          'has_compat_matrix','has_known_risks','has_support_instructions'):
    assert m[k] is True, k
p = json.load(open('release/wiremudder/final/provenance.json'))
assert p['prepared_by_agent'] is True
assert p['signed_by_maintainer'] is False
PY
pass "final boundary honest: agent-prepared, unsigned, auto_deploy=false"

# 5. Physical candidate artifacts verify checksums over real bytes.
(cd release/wiremudder/candidate && sha256sum -c SHA256SUMS >/dev/null) \
  || fail "candidate checksums failed"
"$oracle" dir-check release/wiremudder/candidate 0 >"$out" 2>&1 \
  || fail "dir-check: $(cat "$out")"
grep -q "dir-ok 10" "$out" || fail "dir-check sentinel: $(cat "$out")"
pass "candidate artifact set complete (dir-ok 10), checksums verify"

# 6. Stable refuses the unsigned boundary; candidate passes.
"$oracle" stable-check release/wiremudder/final/manifest.json >"$out" 2>&1
grep -q "stable-incomplete:.*signature" "$out" || fail "stable must refuse unsigned"
"$oracle" candidate-check release/wiremudder/candidate/manifest.json >"$out" 2>&1
grep -q "candidate-complete" "$out" || fail "candidate must be complete"
pass "oracle: stable refuses unsigned, candidate complete"

# 7. Release claims gate under full profile (SPEC-000-R07/R08).
env WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh >"$out" 2>&1 \
  || fail "claims gate: $(cat "$out")"
grep -q "release claims: ok features=244 profile=full" "$out" \
  || fail "claims sentinel: $(cat "$out")"
pass "release claims gate ok (244 features, full profile)"

# 8. Manual publish packet exists with exact steps and NO key exposure
#    (SPEC-028-R06).
packet=docs/wiremudder/ship/MANUAL_PUBLISH_PACKET.md
[ -f "$packet" ] || fail "manual publish packet missing"
grep -qi "sign" "$packet" || fail "packet lacks signing steps"
grep -qi "publish" "$packet" || fail "packet lacks publish steps"
if grep -qiE "BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|sk-[A-Za-z0-9]{20}|ghp_[A-Za-z0-9]{20}|AKIA[0-9A-Z]{16}" "$packet"; then
  fail "packet exposes key material"
fi
pass "manual publish packet present, no key material"

# 9. No signature material anywhere in the release boundary.
if find release/wiremudder -name '*.sig' -o -name '*.asc' -o -name '*.gpg' 2>/dev/null | grep -q .; then
  fail "signature material present"
fi
pass "no signature material in release boundary"

# 10. AUTO_DEPLOY=false at the real layers (SPEC-028-R06, SPEC-000-R10).
set -a; . ./.env; set +a
[ "${WIREMUDDER_AUTO_DEPLOY:-false}" = false ] || fail "auto deploy must be false"
sh scripts/probes/auto_deploy.sh >/dev/null 2>&1 || fail "auto_deploy probe"
pass "auto deploy disabled (SPEC-028-R06)"

echo "LF-039: ok ship-gate 10/10"
