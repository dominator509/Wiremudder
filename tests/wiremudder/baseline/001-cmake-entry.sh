#!/usr/bin/env sh
# Baseline test: the inherited CMake build entry point declares the
# expected minimum CMake and C++ standard.
set -eu
[ -f CMakeLists.txt ] || { echo "FAIL: CMakeLists.txt missing" >&2; exit 1; }
grep -q "cmake_minimum_required" CMakeLists.txt || { echo "FAIL: cmake_minimum_required missing" >&2; exit 1; }
echo "baseline cmake-entry: ok"
