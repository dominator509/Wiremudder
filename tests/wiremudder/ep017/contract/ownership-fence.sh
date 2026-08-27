#!/usr/bin/env sh
# EP-017 contract test: owned features and requirements routed with real
# authorities; milestone fences exist; node owns them.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-017-$m.txt" ] || fail "missing fence $m"
done

for f in WM-FEAT-0039 WM-FEAT-0040 WM-FEAT-0046 WM-FEAT-0047; do
  line=$(grep -P "^${f}\t" .agent/features/FEATURES.tsv) || fail "$f missing from registry"
  printf '%s' "$line" | grep -q "EP-017" || fail "$f not owned by EP-017"
  printf '%s' "$line" | grep -q "LF-017" || fail "$f lacks LF-017 proof"
  grep -q "$f" .agent/node-contracts/EP-017.md || fail "$f absent from contract"
done

for r in WM-SPEC-014-R01 WM-SPEC-014-R03 WM-SPEC-014-R04 \
         WM-SPEC-014-R08 WM-SPEC-014-R09; do
  line=$(grep -P "^${r}\t" .agent/requirements/VALIDATION_MATRIX.tsv) \
    || fail "$r missing from validation matrix"
  printf '%s' "$line" | grep -q "EP-017" || fail "$r not owned by EP-017"
  printf '%s' "$line" | grep -q "LF-017" || fail "$r lacks LF-017 proof"
done

echo "contract ownership-fence: ok"
