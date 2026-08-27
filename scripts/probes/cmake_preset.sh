#!/usr/bin/env sh
set -eu
preset=${WIREMUDDER_CMAKE_PRESET:?}
cmake --list-presets 2>/dev/null | grep -F "\"$preset\"" >/dev/null
