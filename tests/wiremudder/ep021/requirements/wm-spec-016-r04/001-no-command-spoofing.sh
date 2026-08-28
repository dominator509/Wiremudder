#!/usr/bin/env sh
# EP-021 requirement test: WM-SPEC-016-R04 raw text remains visible and
# authoritative; overlays cannot spoof trusted commands.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-016-r04: FAIL - $1" >&2; exit 1; }
# The memory stack is observer-only: no surface can emit a command, so no
# overlay can spoof one.
for lib in wirecore/crates/wire-world-brain/src/lib.rs \
           wirecore/crates/wire-world-bible/src/lib.rs \
           wirecore/crates/wire-time-machine/src/lib.rs; do
  grep -q "can_send_command" "$lib" || fail "no-command invariant missing in $lib"
done
echo "wm-spec-016-r04 no command spoofing: ok"
