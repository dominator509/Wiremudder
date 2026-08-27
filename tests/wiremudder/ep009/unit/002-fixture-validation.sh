#!/usr/bin/env sh
# EP-009 M2 unit test: fixture validation, sanitization, and boundary rules.
set -eu
cd "$(dirname "$0")/../../../.."
ORACLE="python3 compatibility/classic/parity_oracle.py"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

# 1. Unsanitized fixture is rejected (SPEC-005: no passwords/private data)
cat > "$TMP/unsanitized.json" <<'JSON'
{
  "fixture_id": "unsanitized",
  "feature": "WM-FEAT-0002",
  "spec": "WM-SPEC-005-R02",
  "level": "semantic",
  "sanitized": false,
  "reference_trace": [{"seq": 1, "kind": "text_run", "payload": "secret"}],
  "wiremudder_trace": [{"seq": 1, "kind": "text_run", "payload": "secret"}]
}
JSON
if $ORACLE --validate "$TMP/unsanitized.json" >/dev/null 2>&1; then
  fail "unsanitized fixture accepted"
fi

# 2. Invalid level is rejected
cat > "$TMP/badlevel.json" <<'JSON'
{
  "fixture_id": "badlevel",
  "feature": "WM-FEAT-0002",
  "spec": "WM-SPEC-005-R02",
  "level": "fuzzy",
  "sanitized": true,
  "reference_trace": [],
  "wiremudder_trace": []
}
JSON
if $ORACLE --validate "$TMP/badlevel.json" >/dev/null 2>&1; then
  fail "invalid level accepted"
fi

# 3. Missing required keys is rejected
cat > "$TMP/missing.json" <<'JSON'
{
  "fixture_id": "missing",
  "feature": "WM-FEAT-0002",
  "level": "semantic",
  "sanitized": true,
  "reference_trace": [],
  "wiremudder_trace": []
}
JSON
if $ORACLE --validate "$TMP/missing.json" >/dev/null 2>&1; then
  fail "missing keys accepted"
fi

# 4. Duplicate trace seq is rejected
cat > "$TMP/dupseq.json" <<'JSON'
{
  "fixture_id": "dupseq",
  "feature": "WM-FEAT-0002",
  "spec": "WM-SPEC-005-R02",
  "level": "semantic",
  "sanitized": true,
  "reference_trace": [
    {"seq": 1, "kind": "text_run", "payload": "a"},
    {"seq": 1, "kind": "text_run", "payload": "b"}
  ],
  "wiremudder_trace": [{"seq": 1, "kind": "text_run", "payload": "a"}]
}
JSON
if $ORACLE --validate "$TMP/dupseq.json" >/dev/null 2>&1; then
  fail "duplicate seq accepted"
fi

# 5. A valid fixture passes validation
cat > "$TMP/valid.json" <<'JSON'
{
  "fixture_id": "valid",
  "feature": "WM-FEAT-0002",
  "spec": "WM-SPEC-005-R02",
  "level": "semantic",
  "sanitized": true,
  "reference_trace": [{"seq": 1, "kind": "text_run", "payload": "ok"}],
  "wiremudder_trace": [{"seq": 1, "kind": "text_run", "payload": "ok"}]
}
JSON
$ORACLE --validate "$TMP/valid.json" >/dev/null || fail "valid fixture rejected"

# 6. No fixture may embed a credential-shaped value (redaction guard)
if grep -rqE "password|passwd|api[_-]?key|secret" tests/wiremudder/classic/; then
  fail "fixture corpus contains credential-shaped text"
fi

echo "unit EP-009 M2 validation: ok"
