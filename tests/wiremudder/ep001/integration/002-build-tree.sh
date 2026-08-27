#!/usr/bin/env sh
# Integration test: the build tree contains the inherited runtime
# resources and the client binary embeds the qrc Lua/package resources.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"
bin="$builddir/src/mudlet"
[ -d "$builddir/src" ] || { echo "FAIL: build src dir missing" >&2; exit 1; }
[ -f "$bin" ] || { echo "FAIL: client binary missing" >&2; exit 1; }
# Mudlet embeds lua scripts and default packages via Qt resources (qrc);
# the binary must contain the embedded resource names.
strings "$bin" 2>/dev/null | grep -q "echo.xml" || { echo "FAIL: embedded package resource missing" >&2; exit 1; }
strings "$bin" 2>/dev/null | grep -q "utf8_filenames.lua" || { echo "FAIL: embedded lua resource missing" >&2; exit 1; }
echo "integration build-tree: ok"
