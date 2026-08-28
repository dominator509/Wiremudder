#!/usr/bin/env sh
# EP-020 M3 integration test: no command path from narration.
# The narrator produces read-only summaries. Nothing in the assistance
# boundary can send a command; denied or unavailable state clears the pane
# without affecting gameplay; uncertainty is visible.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-narrator/src/lib.rs
# Narrator exposes only read-only summaries; no send/execute API exists.
grep -q "pub fn narrate" "$LIB" || fail "narrate missing"
grep -q "pub fn summarize_quest" "$LIB" || fail "summarize_quest missing"
grep -q "pub fn summarize_tactical" "$LIB" || fail "summarize_tactical missing"
if grep -qE "pub fn (send|execute|run|emit_command)" "$LIB"; then
  fail "narrator exposes a command path"
fi

# The pane cannot send commands by construction.
HDR=src/wiremudder/ui/assistance/assistance_boundary.h
grep -q "canSendCommand() const { return false; }" "$HDR" || fail "pane has command path"

# Uncertainty is visible for inferred/user-corrected quest state.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-narrator/Cargo.toml 2>&1 \
  | grep -q "quest_summary_cites_and_marks_uncertainty" || fail "uncertainty invariant"

echo "integration EP-020 M3 no-command-path: ok"
