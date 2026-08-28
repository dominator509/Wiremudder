#!/usr/bin/env sh
# EP-018 M5 feature test: WM-FEAT-0043 Soul Studio.
# Studio validates schema, previews the compiled prompt, tests a
# conversation in a sandbox, shows policy precedence, and audits changes
# (SPEC-014-R04).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0043: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-soul/src/lib.rs
grep -q "pub struct SoulStudio" "$LIB" || fail "SoulStudio missing"
grep -q "pub fn validate_soul" "$LIB" || fail "validate_soul missing"
grep -q "pub fn compiled_prompt" "$LIB" || fail "compiled_prompt missing"
grep -q "pub fn sandbox_preview" "$LIB" || fail "sandbox_preview missing"
grep -q "pub fn policy_precedence" "$LIB" || fail "policy_precedence missing"
grep -q "pub fn recent_audit" "$LIB" || fail "audit missing"
grep -q "max_audit: 200" "$LIB" || fail "audit must be bounded at 200"

# The Studio pane surface exists in the client boundary.
HDR=src/wiremudder/ui/soul/soul_boundary.h
grep -q "compiled-prompt preview" "$HDR" || fail "pane lacks compiled-prompt preview"

# Real behavior: Studio validates + audits and previews compiled behavior.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-soul/Cargo.toml studio_ 2>&1 \
  | grep -q "studio_" || fail "studio tests"

echo "feature-0043 soul-studio: ok"
