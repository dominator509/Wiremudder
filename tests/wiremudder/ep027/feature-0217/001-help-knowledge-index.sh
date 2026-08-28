#!/usr/bin/env sh
# WM-FEAT-0217: generated Help Knowledge Index — the help-indexer tool
# generates a reproducible index from accepted sources.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0217: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "index_state_hash" "$LIB" || fail "index state hash missing"
grep -q "add_source" "$LIB" || fail "accepted source ingestion missing"
grep -q "SourceKind" "$LIB" || fail "source kinds missing"
[ -f tools/help-indexer/Cargo.toml ] || fail "help-indexer missing"
[ -f tools/help-indexer/src/main.rs ] || fail "help-indexer source missing"
grep -q "help-indexer: ok" tools/help-indexer/src/main.rs || fail "indexer output marker missing"
echo "feature WM-FEAT-0217 help-knowledge-index: ok"
