#!/usr/bin/env sh
# WM-SPEC-020-R01 (live-fire): release channels are development, canary,
# beta, and stable and users select their channel.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

oracle="cargo run --quiet --release --manifest-path packaging/wiremudder/Cargo.toml --bin wire-release-oracle --"

tmp=$(mktemp -d /tmp/ep035_r01_XXXX)
trap 'rm -rf "$tmp"' EXIT
out="$tmp/out.log"

# All four channels exist and are distinct.
$oracle channels >"$out" 2>&1
for c in development canary beta stable; do
  grep -q "channel $c" "$out" || fail "channel $c missing"
done
count=$(grep -c "^channel " "$out")
[ "$count" -eq 4 ] || fail "expected 4 channels, got $count"

# A user-selected channel drives a real candidate artifact set.
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
grep -q "dir-ok 10" "$out" || fail "selected-channel candidate incomplete: $(cat "$out")"

echo "req WM-SPEC-020-R01: ok"
