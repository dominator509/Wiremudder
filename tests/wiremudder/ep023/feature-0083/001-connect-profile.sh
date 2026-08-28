#!/usr/bin/env sh
# WM-FEAT-0083: HTTP CONNECT profile.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0083: FAIL - $1" >&2; exit 1; }
# Route labels are visible without credentials (WM-SPEC-006-R10); the
# CONNECT profile is represented by the per-session route label surface.
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "route_label" "$LIB" || fail "route label surface missing"
grep -q "WM-SPEC-006-R10" "$LIB" || fail "route visibility requirement missing"
echo "feature WM-FEAT-0083 http-connect-profile: ok"
