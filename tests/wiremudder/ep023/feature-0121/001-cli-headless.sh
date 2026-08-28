#!/usr/bin/env sh
# WM-FEAT-0121: CLI/headless sessions.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0121: FAIL - $1" >&2; exit 1; }
[ -f tools/wiremudder-supervisor/Cargo.toml ] || fail "supervisor CLI missing"
[ -f tools/wiremudder-supervisor/src/main.rs ] || fail "supervisor CLI source missing"
grep -q "wire-headless" tools/wiremudder-supervisor/Cargo.toml || fail "CLI does not consume wire-headless"
echo "feature WM-FEAT-0121 cli-headless-sessions: ok"
