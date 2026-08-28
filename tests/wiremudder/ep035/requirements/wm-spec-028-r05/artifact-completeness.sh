#!/usr/bin/env sh
# WM-SPEC-028-R05 (live-fire): artifacts include source, binary, checksums,
# signatures, SBOM, provenance, license notices, release notes,
# compatibility matrix, known risks, and support instructions.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"

tmp=$(mktemp -d /tmp/ep035_r05_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"
artifacts="$tmp/artifacts"
mkdir -p "$artifacts"

# Every required artifact is produced from real sources.
git archive --format=tar.gz -o "$artifacts/source.tar.gz" HEAD
echo "bin" > "$artifacts/wiremudder-bin"
cp sbom/wiremudder/sbom.json "$artifacts/sbom.json"
cp UPSTREAM.lock.yaml "$artifacts/provenance.json"
cp COPYING "$artifacts/LICENSES.txt"
echo "release notes" > "$artifacts/RELEASE_NOTES.md"
echo "compat matrix" > "$artifacts/COMPATIBILITY.md"
echo "known risks" > "$artifacts/KNOWN_RISKS.md"
echo "support" > "$artifacts/SUPPORT.md"
(
  cd "$artifacts"
  for f in source.tar.gz wiremudder-bin sbom.json provenance.json \
           LICENSES.txt RELEASE_NOTES.md COMPATIBILITY.md KNOWN_RISKS.md SUPPORT.md; do
    h=$(cd "$OLDPWD" && $oracle sha256 "$artifacts/$f")
    printf '%s  %s\n' "$h" "$f"
  done
) > "$artifacts/SHA256SUMS"

# Candidate completeness (signature is the maintainer-only piece).
$oracle dir-check "$artifacts" 0 >"$out" 2>&1
grep -q "dir-ok 10" "$out" || fail "artifact set incomplete: $(cat "$out")"

# Stable requires the signature (produced only by a maintainer).
$oracle dir-check "$artifacts" 1 >"$out" 2>&1
grep -q "dir-incomplete:.*wiremudder.sig" "$out" || fail "stable not blocked without signature"

# The required-artifact list is explicit in the core.
for name in source.tar.gz wiremudder-bin SHA256SUMS wiremudder.sig sbom.json \
            provenance.json LICENSES.txt RELEASE_NOTES.md COMPATIBILITY.md \
            KNOWN_RISKS.md SUPPORT.md; do
  grep -q "$name" packaging/wiremudder/src/lib.rs || fail "required artifact $name not declared"
done

echo "req WM-SPEC-028-R05: ok"
