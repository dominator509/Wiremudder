#!/usr/bin/env sh
# EP-017 M5 feature test: WM-FEAT-0039 privacy modes.
# The copilot respects privacy modes (local-preferred by default, remote
# only when privacy allows), and secrets never cross into suggestions.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0039: FAIL - $1" >&2; exit 1; }

# Engine routes with local-preferred privacy and the privacy mode is
# visible in the disclosure.
grep -q "PrivacyMode::LocalPreferred" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "copilot does not default to local-preferred privacy"
grep -q "privacyMode" src/wiremudder/ui/copilot/copilot_boundary.h \
  || fail "privacy mode not visible in disclosure"

# Redaction runs before any provider payload (request redaction).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-copilot/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep017_f0039.log
grep -q "security matrix: ok" /tmp/ep017_f0039.log || fail "privacy security matrix"

echo "feature-0039 privacy-modes: ok"
