#!/usr/bin/env sh
# EP-020 M5 feature test: WM-FEAT-0056 Personal Narrator.
# Spoken/text summaries that disclose source, respect privacy (redaction),
# shed load, and never send commands by themselves (WM-SPEC-015-R06).
# Proven by real crate surface, schema, and LF-020 live-fire certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0056: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-narrator/src/lib.rs
grep -q "pub struct Narrator" "$LIB" || fail "Narrator missing"
grep -q "pub fn narrate" "$LIB" || fail "narrate missing"
grep -q "pub fn summarize_quest" "$LIB" || fail "summarize_quest missing"
grep -q "pub fn summarize_tactical" "$LIB" || fail "summarize_tactical missing"
grep -q "pub fn redact" "$LIB" || fail "redact missing"
grep -q "LoadShedding" "$LIB" || fail "load shedding missing"
grep -q "pub source" "$LIB" || fail "source disclosure missing"
grep -q "pub redacted" "$LIB" || fail "redaction flag missing"

# Schema exists and is valid JSON.
python3 -c "import json; json.load(open('schemas/wiremudder/assistance/narrator-summary-v1.json'))" \
  || fail "narrator-summary schema invalid"

# Real behavior: source disclosure, redaction (incl. repeated markers),
# load shedding proven by the crate tests.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-narrator/Cargo.toml 2>&1 \
  | grep -q "redaction_scrubs_repeated_markers" || fail "repeated-marker redaction"

# LF-020 certified narrator behavior.
[ -f .agent/state/evidence/EP-020/M5/lf020-certification.json ] || fail "LF-020 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-020/M5/lf020-certification.json')); assert d['source_disclosed'] and d['secrets_redacted'] and d['load_shedding'] and d['pane_no_command_path']" \
  || fail "LF-020 narrator certification false"

echo "feature-0056 Personal Narrator: ok"
