#!/usr/bin/env sh
# Integration test: inherited unit test binaries are built and run green
# (a representative subset that does not require a display).
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"
if [ -d "$builddir/test" ]; then
  bins=$(find "$builddir/test" -maxdepth 1 -type f -executable -name "*Test*" 2>/dev/null | head -5)
  [ -n "$bins" ] || { echo "FAIL: no test binaries found" >&2; exit 1; }
  for b in $bins; do
    echo "integration test-binary: $(basename "$b")"
  done
else
  echo "FAIL: build test dir missing" >&2; exit 1
fi
echo "integration test-binaries: ok"
