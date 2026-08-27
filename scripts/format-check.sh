#!/usr/bin/env sh
set -eu
cpp_files=$(find src/wiremudder -type f \( -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) 2>/dev/null | sort || true)
if [ -n "$cpp_files" ]; then
  command -v clang-format >/dev/null 2>&1 || { echo 'format check: FAIL - clang-format missing' >&2; exit 1; }
  printf '%s\n' "$cpp_files" | xargs clang-format --dry-run --Werror
fi
if [ -f wirecore/Cargo.toml ]; then
  command -v cargo >/dev/null 2>&1 || { echo 'format check: FAIL - cargo missing' >&2; exit 1; }
  cargo fmt --manifest-path wirecore/Cargo.toml --all -- --check
fi
echo 'format check: ok'
