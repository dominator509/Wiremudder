#!/usr/bin/env sh
# WM-FEAT-0207: typed RendererEmitCandidate event.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0207: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "pub struct RendererEmitCandidate" "$LIB" || fail "typed candidate missing"
grep -q "pub candidate_id" "$LIB" || fail "candidate id missing"
grep -q "pub fn apply_candidate" "$LIB" || fail "apply path missing"
echo "feature WM-FEAT-0207 typed-renderer-emit-candidate: ok"
