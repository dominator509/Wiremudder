#!/usr/bin/env sh
# WM-SPEC-024-R04: requests carry request, correlation, causation,
# session, profile, deadline, cancellation, sensitivity, and capability
# context.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "pub struct RequestContext" "$LIB" || fail "RequestContext missing"
grep -q "pub request" "$LIB" || fail "request missing"
grep -q "pub correlation" "$LIB" || fail "correlation missing"
grep -q "pub causation" "$LIB" || fail "causation missing"
grep -q "pub session" "$LIB" || fail "session missing"
grep -q "pub profile" "$LIB" || fail "profile missing"
grep -q "pub deadline_ms" "$LIB" || fail "deadline missing"
grep -q "pub cancellation" "$LIB" || fail "cancellation missing"
grep -q "pub sensitivity" "$LIB" || fail "sensitivity missing"
grep -q "pub capability" "$LIB" || fail "capability missing"
echo "requirement WM-SPEC-024-R04 request-context: ok"
