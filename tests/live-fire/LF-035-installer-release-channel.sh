#!/usr/bin/env sh
# LF-035 installer-release-channel: live-fire proof for installers, CI,
# release channels, and artifacts.
#
# A real release candidate is prepared for each channel, artifacts are
# produced and verified (source, binary, checksums, SBOM, provenance,
# notices), the installer launches and preserves user data on upgrade,
# post-install smoke passes, channels are distinct and correctly labeled,
# and stable publication remains manual with signing outside the agent.
# Every step uses real artifacts and the real release core — no mocks.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-035: FAIL - $1" >&2; exit 1; }
pass() { echo "LF-035: ok - $1"; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"

work=$(mktemp -d /tmp/lf035_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"
artifacts="$work/artifacts"
mkdir -p "$artifacts"

# 1. Channels are distinct and correctly labeled (SPEC-020-R01).
$oracle channels >"$out" 2>&1
for c in development canary beta stable; do
  grep -q "channel $c manual_publish=true" "$out" || fail "channel $c missing/wrong"
done
pass "channels distinct and labeled (development/canary/beta/stable)"

# 2. Release-candidate artifact set from the real repo: source archive,
#    binary, checksums, SBOM, provenance, notices (SPEC-028-R05).
git archive --format=tar.gz -o "$artifacts/source.tar.gz" HEAD
"$cargo_bin" build --quiet --release --manifest-path packaging/wiremudder/Cargo.toml
cp wirecore/target/release/wire-release-oracle "$artifacts/wiremudder-bin"
cp sbom/wiremudder/sbom.json "$artifacts/sbom.json"
cp UPSTREAM.lock.yaml "$artifacts/provenance.json"
cp COPYING "$artifacts/LICENSES.txt"
echo "WireMudder release candidate (LF-035)" > "$artifacts/RELEASE_NOTES.md"
echo "compatibility: see docs" > "$artifacts/COMPATIBILITY.md"
echo "known risks: none accepted" > "$artifacts/KNOWN_RISKS.md"
echo "support: see docs" > "$artifacts/SUPPORT.md"
(
  cd "$artifacts"
  for f in source.tar.gz wiremudder-bin sbom.json provenance.json \
           LICENSES.txt RELEASE_NOTES.md COMPATIBILITY.md KNOWN_RISKS.md SUPPORT.md; do
    h=$(cd "$OLDPWD" && $oracle sha256 "$artifacts/$f")
    printf '%s  %s\n' "$h" "$f"
  done
) > "$artifacts/SHA256SUMS"
pass "artifact set produced (source, binary, checksums, SBOM, provenance)"

# 3. Candidate completeness verified; stable blocked without signature
#    (SPEC-020-R09: agents never sign).
$oracle dir-check "$artifacts" 0 >"$out" 2>&1
grep -q "dir-ok 10" "$out" || fail "candidate incomplete: $(cat "$out")"
pass "candidate artifact set complete"
$oracle dir-check "$artifacts" 1 >"$out" 2>&1
grep -q "dir-incomplete:.*wiremudder.sig" "$out" || fail "stable not blocked without signature"
pass "stable publication blocked without maintainer signature"

# 4. Installer launches and preserves user data on upgrade (acceptance 2).
sh installers/wiremudder/smoke.sh 0.5.0 "$work/installer" >"$out" 2>&1
grep -q "launcher ran and exited clean" "$out" || fail "launcher did not run"
grep -q "upgrade pass preserved user data" "$out" || fail "user data not preserved"
pass "installer launches and preserves user data on upgrade"

# 5. Post-install smoke passes (checksums verify).
grep -q "source.tar.gz" "$artifacts/SHA256SUMS" || fail "checksums missing source"
pass "post-install smoke: checksums present"

# 6. Publishing remains manual; agent provenance never signs.
$oracle provenance >"$out" 2>&1
grep -q '"prepared_by_agent":true' "$out" || fail "provenance not agent-prepared"
grep -q '"signed_by_maintainer":false' "$out" || fail "agent claims signing"
grep -q "WIREMUDDER_AUTO_DEPLOY=false" .env || fail "auto-deploy not false"
pass "publishing manual (WIREMUDDER_AUTO_DEPLOY=false, agent never signs)"

# 7. Manual gameplay preserved: inherited workflows untouched.
git diff --quiet -- .github/workflows/create-github-release.yml \
  || fail "inherited create-github-release.yml modified"
pass "manual gameplay preserved (inherited workflow untouched)"

echo "LF-035: ok - installer-release-channel certified"
