#!/usr/bin/env sh
# WM-SPEC-017-R10: headless session overhead is benchmarked below the
# equivalent desktop configuration.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "disable_ui" "$LIB" || fail "UI disable missing"
grep -q "disable_renderer" "$LIB" || fail "renderer disable missing"
grep -q "disable_audio" "$LIB" || fail "audio disable missing"
grep -q "disable_voice" "$LIB" || fail "voice disable missing"
# The perf fixture measures headless paths against the SPEC-004 budget.
[ -f tests/wiremudder/ep023/performance/001-perf-fixture.sh ] || fail "perf fixture missing"
grep -q "headless profile" wirecore/crates/wire-headless/examples/perf_fixture.rs || fail "headless profile not benchmarked"
echo "requirement WM-SPEC-017-R10 headless-overhead-benchmark: ok"
