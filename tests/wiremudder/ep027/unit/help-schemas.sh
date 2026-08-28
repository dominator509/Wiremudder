#!/usr/bin/env sh
# EP-027 M2 unit test: help schemas must exist, be valid JSON, and
# declare the accepted contracts (index sources, field help, ask
# context, coach steps, source index state).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for s in index-entry-v1 field-help-v1 ask-context-v1 coach-step-v1 source-index-state-v1; do
  f="schemas/wiremudder/help/$s.json"
  [ -f "$f" ] || fail "missing schema $f"
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid JSON in $f"
done

grep -q '"command-catalog"' schemas/wiremudder/help/index-entry-v1.json || fail "index lacks command-catalog kind"
grep -q '"source-ref"' schemas/wiremudder/help/index-entry-v1.json || fail "index lacks source-ref kind"
grep -q '"content_hash"' schemas/wiremudder/help/index-entry-v1.json || fail "index lacks content hash"
grep -q '"safe_default"' schemas/wiremudder/help/field-help-v1.json || fail "field help lacks safe default"
grep -q '"privacy_note"' schemas/wiremudder/help/field-help-v1.json || fail "field help lacks privacy note"
grep -q '"sanitized_ui_state"' schemas/wiremudder/help/ask-context-v1.json || fail "ask context lacks sanitized state"
grep -q '"proposal"' schemas/wiremudder/help/coach-step-v1.json || fail "coach step lacks proposal"
grep -q '"secret_entries_skipped"' schemas/wiremudder/help/source-index-state-v1.json || fail "source index lacks secret awareness"
grep -q '"removed"' schemas/wiremudder/help/source-index-state-v1.json || fail "source index lacks removed state"

echo "unit EP-027 help-schemas: ok"
