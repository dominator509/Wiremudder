#!/usr/bin/env sh
# WM-FEAT-0120: Mudlet/MUSHclient/TinTin/zMUD/CMUD importers/research paths
# (research-decision-required). Mudlet is verified; the other formats are
# read-only research paths.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0120: FAIL - $1" >&2; exit 1; }

grep -q "WM-FEAT-0120" .agent/features/FEATURES.tsv || fail "feature missing from FEATURES.tsv"
grep -q "future" .agent/features/FEATURES.tsv || fail "feature not marked future"

# The crate declares verified vs research formats.
grep -q "pub fn is_verified" wirecore/crates/wire-import/src/lib.rs \
  || fail "verified-format gate missing from crate"

# The fallback is declared in the node contract: read-only analysis for
# unproven formats, verified Mudlet imports only.
grep -q "Support read-only analysis and migration reports for unproven formats; allow only verified Mudlet imports" \
  .agent/node-contracts/EP-030.md || fail "research-only fallback not declared"

# Corpus fixtures cover the research formats.
for f in mushclient.xml tintin.tin zmud-cmud.xml generic-json.json generic-csv.csv; do
  [ -f "compatibility/imports/$f" ] || fail "missing corpus fixture $f"
done

echo "feature-0120: ok"
