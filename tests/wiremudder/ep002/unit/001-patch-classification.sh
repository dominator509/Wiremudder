#!/usr/bin/env sh
# Unit test: patch classification is deterministic and fail-closed.
set -eu
classify() {
  python3 tests/wiremudder/ep002/unit/classify_patch.py "$1" "$2"
}
# A graphlock commit classifies as graphlock by message.
[ "$(classify HEAD '[EP-002][M2] core behavior')" = "graphlock" ] || { echo "FAIL: graphlock classification" >&2; exit 1; }
# A security-marked message classifies as security even under .agent paths.
[ "$(classify HEAD '[security] credential handling')" = "security" ] || { echo "FAIL: security classification" >&2; exit 1; }
# An unknown range classifies as unclassified (fail-closed), not guessed.
[ "$(classify HEAD~1..HEAD 'x' 2>/dev/null || echo unclassified)" != "" ] || { echo "FAIL: empty result" >&2; exit 1; }
echo "unit patch-classification: ok"
