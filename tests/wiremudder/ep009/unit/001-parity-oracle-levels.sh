#!/usr/bin/env sh
# EP-009 M2 unit test: parity oracle level semantics and disagreement.
set -eu
cd "$(dirname "$0")/../../../.."
ORACLE="python3 compatibility/classic/parity_oracle.py"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

# 1. All corpus fixtures agree at their declared levels
$ORACLE --compare-all tests/wiremudder/classic || fail "corpus disagreement"

# 2. Exact level rejects whitespace/case difference
cat > "$TMP/exact-mismatch.json" <<'JSON'
{
  "fixture_id": "exact-mismatch",
  "feature": "WM-FEAT-0002",
  "spec": "WM-SPEC-005-R02",
  "level": "exact",
  "sanitized": true,
  "reference_trace": [{"seq": 1, "kind": "text_run", "payload": "Hello World"}],
  "wiremudder_trace": [{"seq": 1, "kind": "text_run", "payload": "Hello  World"}]
}
JSON
if $ORACLE --compare "$TMP/exact-mismatch.json" >/dev/null 2>&1; then
  fail "exact level accepted payload difference"
fi

# 3. Semantic level accepts whitespace/case difference
cat > "$TMP/semantic-match.json" <<'JSON'
{
  "fixture_id": "semantic-match",
  "feature": "WM-FEAT-0005",
  "spec": "WM-SPEC-005-R03",
  "level": "semantic",
  "sanitized": true,
  "reference_trace": [{"seq": 1, "kind": "command_send", "payload": "GO  NORTH"}],
  "wiremudder_trace": [{"seq": 1, "kind": "command_send", "payload": "go north"}]
}
JSON
$ORACLE --compare "$TMP/semantic-match.json" >/dev/null || fail "semantic level rejected normalized match"

# 4. Semantic level rejects wrong event kind
cat > "$TMP/semantic-kind.json" <<'JSON'
{
  "fixture_id": "semantic-kind",
  "feature": "WM-FEAT-0005",
  "spec": "WM-SPEC-005-R03",
  "level": "semantic",
  "sanitized": true,
  "reference_trace": [{"seq": 1, "kind": "command_send", "payload": "go north"}],
  "wiremudder_trace": [{"seq": 1, "kind": "alias_match", "payload": "go north"}]
}
JSON
if $ORACLE --compare "$TMP/semantic-kind.json" >/dev/null 2>&1; then
  fail "semantic level accepted kind mismatch"
fi

# 5. Subset level accepts extra WireMudder events in order
cat > "$TMP/subset-extra.json" <<'JSON'
{
  "fixture_id": "subset-extra",
  "feature": "WM-FEAT-0020",
  "spec": "WM-SPEC-008-R06",
  "level": "subset",
  "sanitized": true,
  "reference_trace": [
    {"seq": 1, "kind": "package_import", "payload": "pack"},
    {"seq": 2, "kind": "automation_available", "payload": "disabled"}
  ],
  "wiremudder_trace": [
    {"seq": 1, "kind": "package_import", "payload": "pack"},
    {"seq": 2, "kind": "confirmation_gate", "payload": "user must confirm"},
    {"seq": 3, "kind": "automation_available", "payload": "disabled"}
  ]
}
JSON
$ORACLE --compare "$TMP/subset-extra.json" >/dev/null || fail "subset level rejected allowed extra event"

# 6. Subset level rejects missing reference event
cat > "$TMP/subset-missing.json" <<'JSON'
{
  "fixture_id": "subset-missing",
  "feature": "WM-FEAT-0020",
  "spec": "WM-SPEC-008-R06",
  "level": "subset",
  "sanitized": true,
  "reference_trace": [
    {"seq": 1, "kind": "package_import", "payload": "pack"},
    {"seq": 2, "kind": "automation_available", "payload": "disabled"}
  ],
  "wiremudder_trace": [
    {"seq": 1, "kind": "package_import", "payload": "pack"}
  ]
}
JSON
if $ORACLE --compare "$TMP/subset-missing.json" >/dev/null 2>&1; then
  fail "subset level accepted missing reference event"
fi

echo "unit EP-009 M2: ok"
