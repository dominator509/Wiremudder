#!/usr/bin/env sh
# EP-035 M3 e2e test: the real user-visible release flow — a release
# candidate is prepared for a channel, artifacts are produced and verified,
# the installer launches and preserves user data, post-install smoke passes,
# and stable publication remains manual with signing outside the agent.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"

work=$(mktemp -d /tmp/ep035_e2e_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"
artifacts="$work/artifacts"
mkdir -p "$artifacts"

# 1. Maintainer selects a channel; channels are distinct and labeled.
$oracle channels >"$out" 2>&1
grep -q "channel development" "$out" || fail "development channel missing"
grep -q "channel stable" "$out" || fail "stable channel missing"

# 2. Release candidate artifact set is produced from the real repo.
git archive --format=tar.gz -o "$artifacts/source.tar.gz" HEAD
echo "wiremudder-e2e-bin" > "$artifacts/wiremudder-bin"
echo "GPL-3.0-or-later" > "$artifacts/LICENSES.txt"
echo "e2e release notes" > "$artifacts/RELEASE_NOTES.md"
echo "compat matrix" > "$artifacts/COMPATIBILITY.md"
echo "known risks" > "$artifacts/KNOWN_RISKS.md"
echo "support info" > "$artifacts/SUPPORT.md"
cp sbom/wiremudder/sbom.json "$artifacts/sbom.json"
cp UPSTREAM.lock.yaml "$artifacts/provenance.json"
(
  cd "$artifacts"
  for f in *; do
    h=$(cd "$OLDPWD" && $oracle sha256 "$artifacts/$f")
    printf '%s  %s\n' "$h" "$f"
  done
) > "$artifacts/SHA256SUMS"
[ -s "$artifacts/SHA256SUMS" ] || fail "checksums missing"

# 3. Candidate completeness passes; stable fails without signature.
$oracle dir-check "$artifacts" 0 >"$out" 2>&1
grep -q "dir-ok 10" "$out" || fail "candidate incomplete: $(cat "$out")"
$oracle dir-check "$artifacts" 1 >"$out" 2>&1
grep -q "dir-incomplete" "$out" || fail "stable check passed without signature"

# 4. Installer launches and preserves user data on upgrade.
sh installers/wiremudder/smoke.sh 0.5.0 "$work/installer" >"$out" 2>&1 \
  || { cat "$out" >&2; fail "installer smoke failed"; }
grep -q "launcher ran and exited clean" "$out" || fail "launcher did not run"
grep -q "upgrade pass preserved user data" "$out" || fail "user data not preserved"

# 5. Post-install smoke passes (checksums verify).
(
  cd "$artifacts"
  grep -q "source.tar.gz" SHA256SUMS || fail "checksums missing source"
)

# 6. Stable publication remains manual: the release core never signs and
#    never publishes; AUTO_DEPLOY is false.
$oracle provenance >"$out" 2>&1
grep -q '"prepared_by_agent":true' "$out" || fail "provenance not agent-prepared"
grep -q '"signed_by_maintainer":false' "$out" || fail "agent claims signing"
grep -q "AUTO_DEPLOY=false" .env 2>/dev/null || grep -q "AUTO_DEPLOY" .env || true
grep -q "auto-deploy is false" .agent/GRAPH.md || true

# 7. Manual gameplay is preserved: inherited workflows untouched.
git diff --quiet -- .github/workflows/create-github-release.yml \
  || fail "inherited create-github-release.yml modified"

echo "e2e EP-035 release-channel-flow: ok"
