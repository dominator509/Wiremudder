#!/usr/bin/env sh
# WM-SPEC-020-R09 (live-fire): autonomous agents may prepare artifacts and
# recommendations but cannot access signing keys or publish stable releases.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"

tmp=$(mktemp -d /tmp/ep035_r09_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

# 1. Agents prepare artifacts: an agent-prepared candidate artifact set
#    passes the candidate completeness check.
mkdir -p "$tmp/artifacts"
git archive --format=tar.gz -o "$tmp/artifacts/source.tar.gz" HEAD
echo "bin" > "$tmp/artifacts/wiremudder-bin"
for name in sbom.json provenance.json LICENSES.txt RELEASE_NOTES.md \
            COMPATIBILITY.md KNOWN_RISKS.md SUPPORT.md; do
  echo "content" > "$tmp/artifacts/$name"
done
(
  cd "$tmp/artifacts"
  for f in *; do
    h=$(cd "$OLDPWD" && $oracle sha256 "$tmp/artifacts/$f")
    printf '%s  %s\n' "$h" "$f"
  done
) > "$tmp/artifacts/SHA256SUMS"
$oracle dir-check "$tmp/artifacts" 0 >"$out" 2>&1
grep -q "dir-ok 10" "$out" || fail "agent candidate not prepared"

# 2. Agents cannot sign: agent-prepared provenance never claims signing.
$oracle provenance >"$out" 2>&1
grep -q '"prepared_by_agent":true' "$out" || fail "provenance not agent-prepared"
grep -q '"signed_by_maintainer":false' "$out" || fail "agent provenance claims signing"

# 3. Agents cannot publish stable: a stable manifest missing the signature
#    is incomplete (fail-closed).
cat > "$tmp/incomplete.json" <<'JSON'
{"schema_version":1,"channel":"stable","version":"1.0.0","upstream_commit":"abc","source_commit":"def","artifacts":[],"has_source_archive":true,"has_binary":true,"has_checksums":true,"has_signature":false,"has_sbom":true,"has_provenance":true,"has_license_notices":true,"has_release_notes":true,"has_compat_matrix":true,"has_known_risks":true,"has_support_instructions":true}
JSON
$oracle stable-check "$tmp/incomplete.json" >"$out" 2>&1
grep -q "stable-incomplete:.*signature" "$out" || fail "unsigned stable not blocked"

# 4. No signing key material exists in the release core.
grep -q "SigningKey\|ed25519\|secret_key" packaging/wiremudder/src/lib.rs \
  && fail "release core contains signing material" || true

echo "req WM-SPEC-020-R09: ok"
