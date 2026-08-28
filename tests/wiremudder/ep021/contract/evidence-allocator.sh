#!/usr/bin/env sh
# EP-021 M1 contract test: evidence ID allocator must not collide.
# The source-evidence recorder must allocate max-existing-ID + 1, never
# len(existing)+1 (which collides after renumbering/repair creates gaps).
# This test fails if the allocator regresses to the colliding form.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

REC=scripts/source_evidence.py
grep -q "max_id" "$REC" || fail "allocator does not scan existing IDs"
if grep -q "evidence_id = f'WM-SRC-{len(existing) + 1:06d}'" "$REC"; then
  fail "allocator regressed to len(existing)+1"
fi
grep -q "re.fullmatch(r'WM-SRC-(\\\\d{6})'" "$REC" || fail "allocator does not parse WM-SRC ids"

echo "contract EP-021 evidence-allocator: ok"
