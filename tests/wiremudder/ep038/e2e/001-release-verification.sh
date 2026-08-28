#!/usr/bin/env sh
# EP-038 M3 e2e test: a release engineer verifies the frozen candidate the
# way a user would — checksums, oracle decision, claims matrix, known
# risks, and the release-notes provenance all agree on one story.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || fail "oracle binary missing"

cand=release/wiremudder/candidate
work=$(mktemp -d /tmp/ep038_e2e_XXXX)
trap 'rm -rf "$work"' EXIT

# 1. A user downloads/points at the candidate dir and verifies checksums.
(cd "$cand" && sha256sum -c SHA256SUMS) >"$work/sums.log" 2>&1 \
  || fail "checksum verification failed"
grep -q "OK" "$work/sums.log" || fail "no OK lines in checksum output"

# 2. The oracle certifies the candidate.
"$oracle" candidate-check "$cand/manifest.json" >"$work/cand.log" 2>&1
grep -q "candidate-complete" "$work/cand.log" || fail "candidate not complete"

# 3. The release claims gate accepts the matrix under the full profile.
WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh >"$work/claims.log" 2>&1 \
  || fail "release claims rejected"
grep -q "release claims: ok features=244 profile=full" "$work/claims.log" \
  || fail "claims gate sentinel wrong: $(cat "$work/claims.log")"

# 4. Known risks and release notes exist and agree on the version.
grep -q "0.9.0-rc1" "$cand/RELEASE_NOTES.md" || fail "release notes version wrong"
grep -q "0.9.0-rc1" "$cand/KNOWN_RISKS.md" || fail "known risks version wrong"
grep -qi "not signed" "$cand/KNOWN_RISKS.md" || fail "unsigned status missing"
[ -f docs/wiremudder/release-candidate/KNOWN_RISKS.md ] || fail "canonical known risks missing"

# 5. The manifest records an unsigned agent-prepared candidate.
grep -q '"has_signature": false' "$cand/manifest.json" || fail "signature flag wrong"
grep -q '"prepared_by_agent": true' "$cand/provenance.json" || fail "provenance not agent-prepared"

# 6. A user can reproduce the source archive from the recorded commit.
src_commit=$(python3 -c "import json;print(json.load(open('$cand/manifest.json'))['source_commit'])")
git rev-parse -q --verify "$src_commit^{commit}" >/dev/null || fail "source commit missing"
actual=$(git archive --format=tar.gz "$src_commit" | sha256sum | cut -d' ' -f1)
recorded=$(python3 -c "import json;[print(a['sha256']) for a in json.load(open('$cand/manifest.json'))['artifacts'] if a['name']=='source.tar.gz']")
[ "$actual" = "$recorded" ] || fail "archive mismatch: got $actual want $recorded"

# 7. The compatibility matrix is present and matches the candidate.
[ -f "$cand/COMPATIBILITY.md" ] || fail "compatibility matrix missing"
grep -q "Linux" "$cand/COMPATIBILITY.md" || fail "compat matrix lacks Linux section"

echo "e2e EP-038 release-verification: ok"
