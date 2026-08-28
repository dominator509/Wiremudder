#!/usr/bin/env sh
# LF-038 release-candidate-full-suite: live-fire proof for Full Release
# Candidate Hardening (EP-038).
#
# The frozen 0.9.0-rc1 candidate is proven end-to-end with real
# artifacts: oracle certification, checksum integrity, reproducible
# source archive, claims gate, provenance honesty, signature omission,
# revocation, known risks, and operations runbook. No mocks — every
# assertion runs the real oracle and the real artifact bytes.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-038: FAIL - $1" >&2; exit 1; }
pass() { echo "LF-038: ok - $1"; }

oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || fail "oracle binary missing (build packaging/wiremudder release first)"

cand=release/wiremudder/candidate
work=$(mktemp -d /tmp/lf038_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. Candidate oracle certification (SPEC-028-R05).
"$oracle" candidate-check "$cand/manifest.json" >"$out" 2>&1
grep -q "candidate-complete" "$out" || fail "candidate not complete"
pass "oracle candidate-complete for 0.9.0-rc1"

# 2. Physical artifact set: all 10 candidate artifacts present.
"$oracle" dir-check "$cand" 0 >"$out" 2>&1
grep -q "dir-ok 10" "$out" || fail "dir-check failed: $(cat "$out")"
pass "artifact dir complete (dir-ok 10)"

# 3. Checksum integrity over real bytes.
(cd "$cand" && sha256sum -c SHA256SUMS >/dev/null) || fail "checksums failed"
pass "SHA256SUMS verifies all 9 content artifacts"

# 4. Source archive reproduces from the recorded commit.
src_commit=$(python3 -c "import json;print(json.load(open('$cand/manifest.json'))['source_commit'])")
git rev-parse -q --verify "$src_commit^{commit}" >/dev/null || fail "source commit missing"
actual=$(git archive --format=tar.gz "$src_commit" | sha256sum | cut -d' ' -f1)
recorded=$(python3 -c "import json;[print(a['sha256']) for a in json.load(open('$cand/manifest.json'))['artifacts'] if a['name']=='source.tar.gz']")
[ "$actual" = "$recorded" ] || fail "source archive not reproducible"
pass "source archive reproducible from $src_commit"

# 5. Release claims gate under the full profile (SPEC-000-R07/R08).
WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh >"$out" 2>&1 \
  || fail "claims gate: $(cat "$out")"
grep -q "release claims: ok features=244 profile=full" "$out" \
  || fail "claims sentinel wrong: $(cat "$out")"
pass "release claims gate ok (244 features, full profile)"

# 6. Provenance honesty: agent-prepared, never signed (SPEC-020-R09).
python3 - <<'PY' || fail "provenance dishonesty"
import json
p = json.load(open('release/wiremudder/candidate/provenance.json'))
assert p['prepared_by_agent'] is True
assert p['signed_by_maintainer'] is False
for k in ('upstream_repository','upstream_commit','source_commit','build_host'):
    assert p.get(k), f"empty {k}"
PY
grep -q '"has_signature": false' "$cand/manifest.json" || fail "signature flag wrong"
pass "provenance honest: agent-prepared, unsigned, real fields"

# 7. Stable channel correctly refuses the unsigned candidate.
"$oracle" stable-check "$cand/manifest.json" >"$out" 2>&1
grep -q "stable-incomplete:.*signature" "$out" || fail "stable must refuse unsigned"
pass "stable-check refuses unsigned candidate"

# 8. Revocation is authoritative (SPEC-028-R07).
"$oracle" revoke wm-0.9.0-rc1 >"$out" 2>&1
grep -q '"manifest_revoked":true' "$out" || fail "revoke missing"
grep -q '"rollout_paused":true' "$out" || fail "pause missing"
pass "revocation authoritative"

# 9. Known risks and operations runbook exist (contract obligations 5-6).
[ -f docs/wiremudder/release-candidate/KNOWN_RISKS.md ] || fail "known risks missing"
[ -f docs/wiremudder/release-candidate/design/001-release-candidate-design.md ] \
  || fail "design doc missing"
[ -f docs/wiremudder/release-candidate/operations/001-release-candidate-operations.md ] \
  || fail "operations runbook missing"
grep -qi "not signed" docs/wiremudder/release-candidate/KNOWN_RISKS.md \
  || fail "known risks lacks unsigned status"
pass "known risks, design, and operations runbook present"

# 10. Auto-deploy remains disabled (SPEC-000-R10).
set -a; . ./.env; set +a
[ "${WIREMUDDER_AUTO_DEPLOY:-false}" = false ] || fail "auto deploy must be false"
pass "auto deploy disabled (SPEC-000-R10)"

echo "LF-038: ok release-candidate-full-suite 10/10"
