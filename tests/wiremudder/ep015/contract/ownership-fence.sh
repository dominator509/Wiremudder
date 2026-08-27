#!/usr/bin/env sh
# EP-015 contract test: owned features and requirements are routed with
# real authorities; milestone fences exist; node owns them.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Milestone fences exist.
for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-015-$m.txt" ] || fail "missing fence $m"
done

# Owned features are routed to EP-015 with LF-015 proof and a test path.
for f in WM-FEAT-0048 WM-FEAT-0049 WM-FEAT-0189 WM-FEAT-0196 WM-FEAT-0197 \
         WM-FEAT-0198 WM-FEAT-0199 WM-FEAT-0200 WM-FEAT-0201 WM-FEAT-0202 \
         WM-FEAT-0203 WM-FEAT-0204 WM-FEAT-0205 WM-FEAT-0206; do
  line=$(grep -P "^${f}\t" .agent/features/FEATURES.tsv) || fail "$f missing from registry"
  printf '%s' "$line" | grep -q "EP-015" || fail "$f not owned by EP-015"
  printf '%s' "$line" | grep -q "LF-015" || fail "$f lacks LF-015 proof"
  printf '%s' "$line" | grep -q "tests/wiremudder/ep015/" || fail "$f lacks ep015 test path"
  grep -q "$f" .agent/node-contracts/EP-015.md || fail "$f absent from contract"
done

# Owned requirements are routed to EP-015 with LF-015 proof.
for r in WM-SPEC-013-R01 WM-SPEC-013-R02 WM-SPEC-013-R05 \
         WM-SPEC-013-R06 WM-SPEC-013-R07 WM-SPEC-013-R09; do
  line=$(grep -P "^${r}\t" .agent/requirements/VALIDATION_MATRIX.tsv) \
    || fail "$r missing from validation matrix"
  printf '%s' "$line" | grep -q "EP-015" || fail "$r not owned by EP-015"
  printf '%s' "$line" | grep -q "LF-015" || fail "$r lacks LF-015 proof"
done

echo "contract ownership-fence: ok"
