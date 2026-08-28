#!/usr/bin/env sh
# WM-FEAT-0081: direct/system-network profile.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0081: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "route_label" "$LIB" || fail "route label missing"
grep -q '"direct"' "$LIB" || fail "direct route default missing"
echo "feature WM-FEAT-0081 direct-system-network-profile: ok"
