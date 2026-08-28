#!/usr/bin/env sh
# EP-031 M5 feature test: cross-cutting accessibility coverage. EP-031 owns
# no direct feature rows (node contract), but it carries the release
# obligation that the SPEC-027-R07 accessibility dimensions are covered
# across enabled surfaces. This test proves the boundary exposes every
# dimension the specification requires: keyboard, focus, semantics
# (screen-reader labels), contrast or non-color state, reduced motion,
# subtitles, and raw-text fallback.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "features: FAIL - $1" >&2; exit 1; }

# 1. SPEC-027-R07 defines the required accessibility dimensions.
grep -q "WM-SPEC-027-R07" .agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md \
  || fail "WM-SPEC-027-R07 missing from SPEC-027"

hdr=src/wiremudder/accessibility/accessibility_boundary.h
[ -f "$hdr" ] || fail "missing accessibility boundary header"

# 2. Keyboard dimension.
grep -q "bool keyboard_operable" "$hdr" || fail "keyboard dimension missing"
# 3. Focus dimension.
grep -q "bool visible_focus" "$hdr" || fail "focus dimension missing"
# 4. Semantics dimension (screen-reader labels).
grep -q "bool screen_reader_labels" "$hdr" || fail "screen-reader semantics dimension missing"
# 5. Contrast / non-color state dimension.
grep -q "bool non_color_state" "$hdr" || fail "non-color state dimension missing"
# 6. Reduced motion dimension.
grep -q "bool reduced_motion" "$hdr" || fail "reduced-motion dimension missing"
# 7. No-animation dimension.
grep -q "bool no_animation" "$hdr" || fail "no-animation dimension missing"
# 8. Subtitles dimension.
grep -q "bool subtitles_available" "$hdr" || fail "subtitles dimension missing"
# 9. Raw-text fallback dimension.
grep -q "bool raw_text_mode" "$hdr" || fail "raw-text fallback dimension missing"
grep -q "bool raw_text_authoritative" "$hdr" || fail "raw-text authority dimension missing"

# 10. The boundary cannot disable raw text (fallback is invariant).
grep -q "bool canDisableRawText() const { return false; }" "$hdr" \
  || fail "raw-text fallback can be disabled"

echo "features EP-031 cross-cutting-accessibility-coverage: ok"
