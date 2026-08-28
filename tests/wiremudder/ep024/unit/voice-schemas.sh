#!/usr/bin/env sh
# EP-024 M2 unit test: voice schemas must exist, be valid JSON, and
# declare the accepted contracts (companion state with always-visible
# mic, macro command-safety, licensed styles, transcript retention,
# remote consent).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for s in companion-state-v1 macro-v1 style-v1 transcript-v1 remote-policy-v1; do
  f="schemas/wiremudder/voice/$s.json"
  [ -f "$f" ] || fail "missing schema $f"
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid JSON in $f"
done

grep -q '"mic"' schemas/wiremudder/voice/companion-state-v1.json || fail "companion-state lacks mic"
grep -q '"queue_len"' schemas/wiremudder/voice/companion-state-v1.json || fail "companion-state lacks queue"
grep -q '"risk_tier"' schemas/wiremudder/voice/macro-v1.json || fail "macro lacks risk tier"
grep -q '"confirmation_required"' schemas/wiremudder/voice/macro-v1.json || fail "macro lacks confirmation"
grep -q '"authorized"' schemas/wiremudder/voice/style-v1.json || fail "style lacks authorization"
grep -q '"protected"' schemas/wiremudder/voice/style-v1.json || fail "style lacks protected flag"
grep -q '"private"' schemas/wiremudder/voice/transcript-v1.json || fail "transcript lacks privacy"
grep -q '"consent_receipts"' schemas/wiremudder/voice/remote-policy-v1.json || fail "remote policy lacks consent"
grep -q '"revoked"' schemas/wiremudder/voice/remote-policy-v1.json || fail "consent lacks revocation"

[ -f config/wiremudder/voice/voice.yaml ] || fail "missing voice config"
grep -q "mic_visibility: always" config/wiremudder/voice/voice.yaml || fail "config lacks mic visibility"
grep -q "wake_phrase" config/wiremudder/voice/voice.yaml || fail "config lacks wake phrase"
grep -q "local_only: true" config/wiremudder/voice/voice.yaml || fail "config lacks local-only default"

echo "unit voice-schemas: ok"
