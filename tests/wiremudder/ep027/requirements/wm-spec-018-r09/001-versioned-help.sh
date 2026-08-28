#!/usr/bin/env sh
# WM-SPEC-018-R09: Help content is versioned with the app and reports
# when an answer relies on stale or unavailable source evidence.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

grep -q "WM-SPEC-018-R09: Help content is versioned with the app" \
  .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "WM-SPEC-018-R09 missing from SPEC-018"

LIB=wirecore/crates/wire-help/src/lib.rs
grep -q "app_version" "$LIB" || fail "app version missing"
grep -q "source_version" "$LIB" || fail "source version missing"
grep -q "StaleSource" "$LIB" || fail "stale-source report missing"
grep -q "UnavailableSource" "$LIB" || fail "unavailable-source report missing"
grep -q "answer_reports_stale_source" "$LIB" || fail "stale-source test missing"
grep -q "versioned_with_app" "$LIB" || fail "versioned-with-app test missing"

echo "requirement WM-SPEC-018-R09 versioned-help: ok"
