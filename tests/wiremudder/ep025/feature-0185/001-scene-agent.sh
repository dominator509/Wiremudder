#!/usr/bin/env sh
# WM-FEAT-0185: Renderer Scene Agent with evidence, safety, rollback,
# and release-profile controls.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0185: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "RendererEmitCandidate" "$LIB" || fail "renderer scene candidate missing"
grep -q "pub evidence" "$LIB" || fail "evidence field missing"
grep -q "pub suggested_by" "$LIB" || fail "suggested-by field missing"
grep -q "pub confidence" "$LIB" || fail "confidence field missing"
grep -q "scene-agent" "$LIB" || fail "scene agent missing"
echo "feature WM-FEAT-0185 renderer-scene-agent: ok"
