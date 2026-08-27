#!/usr/bin/env sh
# Contract test: inherited fake-MUD-server and session fixtures exist
# (the oracle must be independent of implementation tests).
set -eu
[ -f test/functional_tests/TelnetServerStub.h ] || { echo "FAIL: TelnetServerStub.h missing" >&2; exit 1; }
[ -f test/functional_tests/TelnetServerStub.cpp ] || { echo "FAIL: TelnetServerStub.cpp missing" >&2; exit 1; }
[ -f test/functional_tests/TelnetTextDisplayedTest.cpp ] || { echo "FAIL: session test missing" >&2; exit 1; }
echo "contract inherited-oracle-fixtures: ok"
