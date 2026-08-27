#!/usr/bin/env sh
# EP-016 M2 unit test: provider config is valid and remote stays disabled.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -f config/wiremudder/providers/providers.example.json ] || fail "missing providers config"
[ -f config/wiremudder/providers/routing-policy.example.json ] || fail "missing routing policy"
python3 -c "import json; json.load(open('config/wiremudder/providers/providers.example.json'))" \
  || fail "invalid providers config JSON"
python3 -c "import json; json.load(open('config/wiremudder/providers/routing-policy.example.json'))" \
  || fail "invalid routing policy JSON"

# Acceptance obligation 6: uncertified adapters stay disabled and unadvertised.
# The remote provider must never be certified or configured in the default config.
grep -q '"remote-placeholder"' config/wiremudder/providers/providers.example.json \
  || fail "remote placeholder missing"
grep -q '"configured": false' config/wiremudder/providers/providers.example.json \
  || fail "remote adapter must stay unconfigured by default"
grep -q '"certified": false' config/wiremudder/providers/providers.example.json \
  || fail "remote adapter must stay uncertified by default"

echo "unit EP-016 M2 provider-config: ok"
