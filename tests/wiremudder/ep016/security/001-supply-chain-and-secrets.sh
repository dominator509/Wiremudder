#!/usr/bin/env sh
# EP-016 M4 security: secrets never committed, supply chain pinned, and
# redacted user-facing output in the shipped docs/config.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

# 1. Supply chain: crates depend only on the pinned repository set.
for dep in wire-provider-adapters wire-ai-router; do
  cargo_file="wirecore/crates/$dep/Cargo.toml"
  [ -f "$cargo_file" ] || fail "missing $cargo_file"
  bad=$(grep -E '^\s*(reqwest|hyper|tokio|rusqlite|openai|ollama|curl|ureq|http)\s*=' "$cargo_file" || true)
  [ -z "$bad" ] || fail "$dep pulls unexpected dependency: $bad"
done
# The adapters crate may only use serde/serde_json/regex/wire-privacy.
bad=$(awk '/^\[dependencies\]/{f=1;next} /^\[/{f=0} f' wirecore/crates/wire-provider-adapters/Cargo.toml \
  | grep -E '^[a-z-]+ = ' \
  | grep -vE 'serde|serde_json|regex|wire-privacy' || true)
[ -z "$bad" ] || fail "wire-provider-adapters unexpected dep: $bad"

# 2. No secret-shaped content committed under the EP-016 tree. Test fixture
#    strings inside #[cfg(test)] modules in crate sources are intentional
#    (they prove redaction) and are already gated by the crate unit tests;
#    the scan therefore covers committed config, docs, schemas, examples,
#    test scripts, and manifests.
hits=$(grep -rInE 'sk-(live|test|proj)-[A-Za-z0-9]{12,}|api_key[=:][[:space:]]*[A-Za-z0-9]{16,}|password[=:][[:space:]]*[A-Za-z0-9]{8,}' \
  tests/wiremudder/ep016 wirecore/crates/wire-ai-router/examples wirecore/crates/wire-provider-adapters/examples \
  config/wiremudder/providers schemas/wiremudder/ai docs/wiremudder/ai-providers 2>/dev/null || true)
[ -z "$hits" ] || fail "secret-shaped content committed:\n$hits"

# 3. The design doc's observed provider behavior carries no live secrets.
grep -q "api.chat" docs/wiremudder/ai-providers/design/design.md || fail "design doc missing provider evidence"

echo "security EP-016 M4 supply-chain-and-secrets: ok"
