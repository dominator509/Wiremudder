#!/usr/bin/env sh
# Unit test: baseline toolchain is present and satisfies inherited build
# requirements (CMake >= 3.25.1, Ninja, g++, Lua 5.1, Qt6).
set -eu
cmake_major=$(cmake --version | awk 'NR==1 {print $3}' | cut -d. -f1)
cmake_minor=$(cmake --version | awk 'NR==1 {print $3}' | cut -d. -f2)
[ "$cmake_major" -ge 3 ] && { [ "$cmake_major" -gt 3 ] || [ "$cmake_minor" -ge 25 ]; } || { echo "FAIL: cmake too old" >&2; exit 1; }
command -v ninja >/dev/null || { echo "FAIL: ninja missing" >&2; exit 1; }
command -v g++ >/dev/null || { echo "FAIL: g++ missing" >&2; exit 1; }
lua5.1 -v 2>&1 | grep -q "5.1" || { echo "FAIL: lua5.1 missing" >&2; exit 1; }
pkg-config --exists Qt6Core || { echo "FAIL: Qt6Core missing" >&2; exit 1; }
ver=$(pkg-config --modversion Qt6Core)
echo "unit toolchain: ok cmake=$(cmake --version | head -1 | awk '{print $3}') qt=$ver"
