#!/usr/bin/env sh
# EP-038 M2 unit test: candidate manifest invariants. The real oracle
# binary decides completeness; every assertion uses real bytes.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || fail "oracle binary missing (build packaging/wiremudder release first)"

work=$(mktemp -d /tmp/ep038_unit_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. The real frozen candidate is complete for candidate channel.
"$oracle" candidate-check release/wiremudder/candidate/manifest.json >"$out" 2>&1 \
  || fail "real candidate rejected: $(cat "$out")"
grep -q "candidate-complete" "$out" || fail "candidate-complete sentinel missing"

# 2. The same manifest is NOT stable-complete: an agent never signs.
"$oracle" stable-check release/wiremudder/candidate/manifest.json >"$out" 2>&1
grep -q "stable-incomplete:.*signature" "$out" \
  || fail "unsigned candidate must not pass stable-check"

# 3. A manifest that omits the binary fails candidate-check with the
#    exact missing name.
cat > "$work/no-bin.json" <<'JSON'
{"schema_version":1,"channel":"canary","version":"0.9.0-rc1","upstream_commit":"abc","source_commit":"def","artifacts":[],"has_source_archive":true,"has_binary":false,"has_checksums":true,"has_signature":false,"has_sbom":true,"has_provenance":true,"has_license_notices":true,"has_release_notes":true,"has_compat_matrix":true,"has_known_risks":true,"has_support_instructions":true}
JSON
"$oracle" candidate-check "$work/no-bin.json" >"$out" 2>&1
grep -q "candidate-incomplete:.*binary" "$out" \
  || fail "missing binary not flagged: $(cat "$out")"

# 4. Missing provenance is also flagged (candidate cannot omit it).
cat > "$work/no-prov.json" <<'JSON'
{"schema_version":1,"channel":"canary","version":"0.9.0-rc1","upstream_commit":"abc","source_commit":"def","artifacts":[],"has_source_archive":true,"has_binary":true,"has_checksums":true,"has_signature":false,"has_sbom":true,"has_provenance":false,"has_license_notices":true,"has_release_notes":true,"has_compat_matrix":true,"has_known_risks":true,"has_support_instructions":true}
JSON
"$oracle" candidate-check "$work/no-prov.json" >"$out" 2>&1
grep -q "candidate-incomplete:.*provenance" "$out" \
  || fail "missing provenance not flagged: $(cat "$out")"

# 5. sha256 subcommand matches the system sha256sum on real bytes.
echo "deterministic-invariant" > "$work/probe.txt"
"$oracle" sha256 "$work/probe.txt" >"$out" 2>&1
expected=$(sha256sum "$work/probe.txt" | cut -d' ' -f1)
grep -q "$expected" "$out" || fail "sha256 mismatch: $(cat "$out")"

# 6. dir-check: the physical candidate dir carries all 10 candidate
#    artifacts; signature required variant fails (no wiremudder.sig).
"$oracle" dir-check release/wiremudder/candidate 0 >"$out" 2>&1
grep -q "dir-ok 10" "$out" || fail "dir-check wrong: $(cat "$out")"
"$oracle" dir-check release/wiremudder/candidate 1 >"$out" 2>&1
grep -q "dir-incomplete:.*wiremudder.sig" "$out" \
  || fail "signature-required dir-check must fail: $(cat "$out")"

# 7. SHA256SUMS in the candidate dir verifies against real bytes.
(cd release/wiremudder/candidate && sha256sum -c SHA256SUMS >/dev/null) \
  || fail "SHA256SUMS verification failed"

# 8. Provenance: agent-prepared, never signed.
"$oracle" provenance >"$out" 2>&1
grep -q '"prepared_by_agent":true' "$out" || fail "provenance not agent-prepared"
grep -q '"signed_by_maintainer":false' "$out" || fail "provenance claims signing"

# 9. Revocation: rollout control pauses and revokes.
"$oracle" revoke wm-0.9.0-rc1 >"$out" 2>&1
grep -q '"manifest_revoked":true' "$out" || fail "revocation missing"
grep -q '"rollout_paused":true' "$out" || fail "rollout not paused"

# 10. Sync readiness: unrehearsed rehearsal is reported, not claimed.
"$oracle" sync-ready release/wiremudder/candidate/manifest.json >"$out" 2>&1
grep -q "sync-pending:" "$out" || fail "sync rehearsal not reported pending"

# 11. Oracle fails closed: unknown subcommand exits nonzero with FAIL.
if "$oracle" no-such-subcommand >"$out" 2>&1; then
  fail "unknown subcommand must fail"
fi

echo "unit EP-038 candidate-invariants: ok"
