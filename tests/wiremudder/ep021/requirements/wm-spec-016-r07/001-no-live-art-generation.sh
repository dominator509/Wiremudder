#!/usr/bin/env sh
# EP-021 requirement test: WM-SPEC-016-R07 no live art generation in the
# hot path; generation is out of band and consented.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-016-r07: FAIL - $1" >&2; exit 1; }
# World Bible stores text metadata only; no live generation exists in the
# memory stack.
LIB=wirecore/crates/wire-world-bible/src/lib.rs
grep -q "no_protected_assets" "$LIB" || fail "no-assets invariant missing"
for lib in wirecore/crates/wire-world-brain/src/lib.rs \
           wirecore/crates/wire-world-bible/src/lib.rs \
           wirecore/crates/wire-time-machine/src/lib.rs; do
  if grep -qE "pub fn (generate|render)" "$lib"; then
    fail "live generation claimed without certification: $lib"
  fi
done
echo "wm-spec-016-r07 no live art generation: ok"
