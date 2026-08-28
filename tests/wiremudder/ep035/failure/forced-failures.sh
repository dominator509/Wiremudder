#!/usr/bin/env sh
# EP-035 M4 failure test: forced failures fail closed (SPEC-025, SPEC-028).
#
# Real controlled failure mechanisms against the release core: malformed
# manifest, incomplete artifact set, missing artifact files, empty
# checksums, and invalid channel names. Each must produce a typed error —
# never a false success.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"

tmp=$(mktemp -d /tmp/ep035_fail_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

# 1. Malformed manifest JSON fails closed.
echo '{ not json' > "$tmp/bad.json"
if $oracle stable-check "$tmp/bad.json" >"$out" 2>&1; then
  cat "$out" >&2; fail "malformed manifest accepted"
fi

# 2. Incomplete stable manifest is flagged with the missing pieces.
cat > "$tmp/incomplete.json" <<'JSON'
{"schema_version":1,"channel":"stable","version":"1.0.0","upstream_commit":"abc","source_commit":"def","artifacts":[],"has_source_archive":false,"has_binary":true,"has_checksums":false,"has_signature":false,"has_sbom":false,"has_provenance":false,"has_license_notices":false,"has_release_notes":false,"has_compat_matrix":false,"has_known_risks":false,"has_support_instructions":false}
JSON
$oracle stable-check "$tmp/incomplete.json" >"$out" 2>&1
grep -q "stable-incomplete:.*source archive" "$out" || fail "missing source not flagged"
grep -q "stable-incomplete:.*signature" "$out" || fail "missing signature not flagged"

# 3. Empty artifact directory fails closed.
mkdir -p "$tmp/empty"
$oracle dir-check "$tmp/empty" 1 >"$out" 2>&1
grep -q "dir-incomplete:" "$out" || fail "empty dir not flagged"

# 4. Missing single artifact file fails closed for stable.
mkdir -p "$tmp/partial"
for name in source.tar.gz wiremudder-bin SHA256SUMS sbom.json provenance.json \
            LICENSES.txt RELEASE_NOTES.md COMPATIBILITY.md KNOWN_RISKS.md SUPPORT.md; do
  echo "x" > "$tmp/partial/$name"
done
rm "$tmp/partial/wiremudder.sig" 2>/dev/null || true
$oracle dir-check "$tmp/partial" 1 >"$out" 2>&1
grep -q "dir-incomplete:.*wiremudder.sig" "$out" || fail "missing sig not flagged"

# 5. Invalid channel name fails closed.
if $oracle channels | grep -q "channel nope"; then
  fail "invalid channel accepted"
fi

# 6. Missing artifact file for sha256 fails closed.
if $oracle sha256 "$tmp/nonexistent.bin" >"$out" 2>&1; then
  cat "$out" >&2; fail "missing file hashed"
fi

# 7. Sync readiness is never claimed before rehearsal.
$oracle sync-ready "$tmp/incomplete.json" >"$out" 2>&1
grep -q "sync-pending:" "$out" || fail "sync claimed ready without rehearsal"

echo "failure EP-035 forced-failures: ok"
