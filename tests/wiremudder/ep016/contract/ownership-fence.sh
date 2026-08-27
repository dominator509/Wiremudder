#!/usr/bin/env sh
# EP-016 contract test: owned features and requirements routed with real
# authorities; milestone fences exist; node owns them.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-016-$m.txt" ] || fail "missing fence $m"
done

for f in WM-FEAT-0037 WM-FEAT-0038; do
  line=$(grep -P "^${f}\t" .agent/features/FEATURES.tsv) || fail "$f missing from registry"
  printf '%s' "$line" | grep -q "EP-016" || fail "$f not owned by EP-016"
  printf '%s' "$line" | grep -q "LF-016" || fail "$f lacks LF-016 proof"
  grep -q "$f" .agent/node-contracts/EP-016.md || fail "$f absent from contract"
done

for r in WM-SPEC-013-R03 WM-SPEC-013-R04 WM-SPEC-013-R08 \
         WM-SPEC-013-R10 WM-SPEC-025-R07 WM-SPEC-025-R09; do
  line=$(grep -P "^${r}\t" .agent/requirements/VALIDATION_MATRIX.tsv) \
    || fail "$r missing from validation matrix"
  printf '%s' "$line" | grep -q "EP-016" || fail "$r not owned by EP-016"
  printf '%s' "$line" | grep -q "LF-016" || fail "$r lacks LF-016 proof"
done

echo "contract ownership-fence: ok"
