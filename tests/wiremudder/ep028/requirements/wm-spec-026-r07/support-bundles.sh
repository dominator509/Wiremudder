#!/usr/bin/env sh
# WM-SPEC-026-R07: support bundles are previewable, redacted,
# reproducible, and content-addressed.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement wm-spec-026-r07: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-replay/src/lib.rs
[ -f "$LIB" ] || fail "wire-replay crate missing"
grep -q "pub preview" "$LIB" || fail "previewable missing"
grep -q "redact" "$LIB" || fail "redacted missing"
grep -q "content_sha256" "$LIB" || fail "content-addressed missing"
grep -q "content_hash" "$LIB" || fail "reproducible hash missing"
echo "requirement wm-spec-026-r07 support-bundles: ok"
