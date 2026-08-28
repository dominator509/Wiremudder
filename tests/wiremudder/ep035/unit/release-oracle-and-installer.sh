#!/usr/bin/env sh
# EP-035 M2 unit test: the release oracle drives the real core against real
# artifact directories — channel list, stable/candidate completeness,
# SHA256 computation, artifact-dir checks, provenance, revocation, and sync
# readiness. The installer smoke proves launch + user-data preservation.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"

work=$(mktemp -d /tmp/ep035_unit_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. Channels: four distinct, correctly labeled, all manual-publish.
$oracle channels >"$out" 2>&1
for c in development canary beta stable; do
  grep -q "channel $c manual_publish=true" "$out" || fail "channel $c missing/wrong"
done

# 2. Stable completeness: a complete manifest passes; incomplete fails.
cat > "$work/complete.json" <<'JSON'
{"schema_version":1,"channel":"stable","version":"1.0.0","upstream_commit":"abc","source_commit":"def","artifacts":[],"has_source_archive":true,"has_binary":true,"has_checksums":true,"has_signature":true,"has_sbom":true,"has_provenance":true,"has_license_notices":true,"has_release_notes":true,"has_compat_matrix":true,"has_known_risks":true,"has_support_instructions":true}
JSON
$oracle stable-check "$work/complete.json" >"$out" 2>&1
grep -q "stable-complete" "$out" || fail "complete stable manifest rejected"

cat > "$work/incomplete.json" <<'JSON'
{"schema_version":1,"channel":"stable","version":"1.0.0","upstream_commit":"abc","source_commit":"def","artifacts":[],"has_source_archive":true,"has_binary":true,"has_checksums":true,"has_signature":false,"has_sbom":true,"has_provenance":false,"has_license_notices":true,"has_release_notes":true,"has_compat_matrix":true,"has_known_risks":true,"has_support_instructions":true}
JSON
$oracle stable-check "$work/incomplete.json" >"$out" 2>&1
grep -q "stable-incomplete:.*signature" "$out" || fail "incomplete stable not flagged"

# 3. Candidate completeness: signature may be omitted by agents.
$oracle candidate-check "$work/incomplete.json" >"$out" 2>&1
grep -q "candidate-incomplete:.*provenance" "$out" || fail "candidate missing provenance not flagged"

# 4. SHA256: real bytes hash correctly.
echo "hello" > "$work/hello.txt"
$oracle sha256 "$work/hello.txt" >"$out" 2>&1
expected=$(printf 'hello\n' | sha256sum | cut -d' ' -f1)
grep -q "$expected" "$out" || fail "sha256 mismatch: $(cat "$out")"

# 5. Artifact dir check: complete dir passes, missing signature fails for
#    stable but passes for candidate.
mkdir -p "$work/artifacts"
for name in source.tar.gz wiremudder-bin SHA256SUMS sbom.json provenance.json \
            LICENSES.txt RELEASE_NOTES.md COMPATIBILITY.md KNOWN_RISKS.md SUPPORT.md; do
  echo "$name-content" > "$work/artifacts/$name"
done
$oracle dir-check "$work/artifacts" 0 >"$out" 2>&1
grep -q "dir-ok 10" "$out" || fail "candidate dir-check wrong: $(cat "$out")"

# 6. Provenance: agent-prepared, never signed.
$oracle provenance >"$out" 2>&1
grep -q '"prepared_by_agent":true' "$out" || fail "provenance not agent-prepared"
grep -q '"signed_by_maintainer":false' "$out" || fail "provenance claims signing"

# 7. Revocation: rollout control pauses and revokes.
$oracle revoke wm-1.0.0 >"$out" 2>&1
grep -q '"manifest_revoked":true' "$out" || fail "revocation missing"
grep -q '"rollout_paused":true' "$out" || fail "rollout not paused"

# 8. Sync readiness: pending rehearsal is reported, not claimed.
$oracle sync-ready "$work/complete.json" >"$out" 2>&1
grep -q "sync-pending:" "$out" || fail "sync rehearsal not reported pending"

# 9. Installer smoke: launch + user-data preservation on upgrade.
sh installers/wiremudder/smoke.sh 0.5.0 "$work/installer" >"$out" 2>&1 \
  || { cat "$out" >&2; fail "installer smoke failed"; }
grep -q "installer-smoke: ok" "$out" || fail "installer smoke sentinel missing"

echo "unit EP-035 release-oracle-and-installer: ok"
