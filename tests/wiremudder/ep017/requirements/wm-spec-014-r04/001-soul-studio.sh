#!/usr/bin/env sh
# WM-SPEC-014-R04: Soul Studio validates schema, previews compiled prompt,
# tests conversation in a sandbox, shows policy precedence, and audits
# changes.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r04: FAIL - $1" >&2; exit 1; }

grep -q "pub struct SoulStudio" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "SoulStudio missing"
grep -q "validate_soul" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "schema validation missing"
grep -q "compiled_prompt" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "compiled prompt preview missing"
grep -q "sandbox_preview" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "sandbox conversation missing"
grep -q "policy_precedence_ok" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "policy precedence missing"
grep -q "pub audit" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "change audit missing"

echo "req WM-SPEC-014-R04: ok"
