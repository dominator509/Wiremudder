#!/usr/bin/env sh
# EP-027 M2 unit test: the help-indexer tool must run from the repo
# root, ingest all accepted source kinds, and produce a reproducible
# index (identical output on identical inputs).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out1=$(mktemp /tmp/ep027_index1_XXXX.json)
out2=$(mktemp /tmp/ep027_index2_XXXX.json)
log1=$(mktemp /tmp/ep027_index1_XXXX.log)
log2=$(mktemp /tmp/ep027_index2_XXXX.log)

CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet \
  --manifest-path tools/help-indexer/Cargo.toml -- "$out1" >"$log1" 2>&1 || {
  cat "$log1" >&2
  fail "help-indexer run 1 failed"
}
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet \
  --manifest-path tools/help-indexer/Cargo.toml -- "$out2" >"$log2" 2>&1 || {
  cat "$log2" >&2
  fail "help-indexer run 2 failed"
}

grep -q "help-indexer: ok" "$log1" || fail "indexer did not report ok"
cmp "$out1" "$out2" || fail "index output is not reproducible"

python3 - "$out1" <<'PY' || fail "index content invalid"
import json, sys
d = json.load(open(sys.argv[1]))
kinds = {e["kind"] for e in d["entries"]}
assert len(d["entries"]) >= 50, f"too few entries: {len(d['entries'])}"
for k in ["docs", "ui-schema", "command-catalog", "config-schema", "adr", "source-ref"]:
    assert k in kinds, f"missing source kind {k}"
assert d["app_version"], "missing app version"
assert d["index_state_hash"], "missing index state hash"
PY

echo "unit EP-027 help-indexer: ok"
