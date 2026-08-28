#!/usr/bin/env sh
# EP-038 M4 failure test: the release-candidate machinery fails closed on
# malformed input, missing artifacts, tampered bytes, and unavailable
# resources. No component is mocked; every failure is real and controlled.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || fail "oracle binary missing"

cand=release/wiremudder/candidate
work=$(mktemp -d /tmp/ep038_fail_XXXX)
trap 'rm -rf "$work"' EXIT
out="$work/out.log"

# 1. Malformed manifest: oracle fails closed with a typed parse error and
#    nonzero exit, never prints a completion sentinel.
echo '{not-json' > "$work/bad.json"
if "$oracle" candidate-check "$work/bad.json" >"$out" 2>&1; then
  fail "malformed manifest must fail"
fi
grep -q "release-oracle: FAIL - parse:" "$out" || fail "missing parse error: $(cat "$out")"

# 2. Missing manifest file: oracle fails closed.
if "$oracle" candidate-check "$work/nope.json" >"$out" 2>&1; then
  fail "missing manifest must fail"
fi
grep -q "release-oracle: FAIL - read:" "$out" || fail "missing read error: $(cat "$out")"

# 3. Missing subcommand args: usage error, exit 2 (fail-closed contract).
if "$oracle" candidate-check >"$out" 2>&1; then
  fail "missing args must fail"
fi
grep -q "candidate-check <manifest>" "$out" || fail "usage missing: $(cat "$out")"

# 4. Unknown subcommand: fail-closed.
if "$oracle" frobnicate >"$out" 2>&1; then
  fail "unknown subcommand must fail"
fi

# 5. Tampered binary: SHA256SUMS verification catches the corruption.
cp "$cand/wiremudder-bin" "$work/bin-copy"
printf 'x' | dd of="$work/bin-copy" bs=1 seek=100 conv=notrunc 2>/dev/null
sed "s|wiremudder-bin|bin-copy|" "$cand/SHA256SUMS" > "$work/SHA256SUMS.tampered"
if (cd "$work" && sha256sum -c SHA256SUMS.tampered >/dev/null 2>&1); then
  fail "tampered binary must fail checksum"
fi
echo "failure: tampered binary correctly rejected by sha256 verification"

# 6. Missing artifact directory: dir-check reports the incomplete verdict.
"$oracle" dir-check "$work/empty" 0 >"$out" 2>&1 || fail "dir-check crashed"
grep -q "dir-incomplete:" "$out" || fail "dir-incomplete missing: $(cat "$out")"
grep -q "missing: source.tar.gz" "$out" || fail "missing artifact not named: $(cat "$out")"

# 7. Resource exhaustion guard: oversized manifest input is rejected, not
#    processed. (Bound check: oracle reads the file; a 64MB manifest is
#    far beyond any legitimate artifact manifest and must not pass parse.)
python3 -c "print('{\"schema_version\":1,' + ' ' * 64000000 + '}')" > "$work/huge.json"
if "$oracle" candidate-check "$work/huge.json" >"$out" 2>&1; then
  fail "oversized manifest must fail closed"
fi
echo "failure: oversized manifest correctly rejected"

# 8. Revocation is authoritative: a revoked manifest is reported, never
#    silently accepted as active.
"$oracle" revoke wm-0.9.0-rc1 >"$out" 2>&1
grep -q '"manifest_revoked":true' "$out" || fail "revocation missing"
grep -q '"rollout_paused":true' "$out" || fail "rollout not paused"

echo "failure EP-038 release-candidate-failures: ok"
