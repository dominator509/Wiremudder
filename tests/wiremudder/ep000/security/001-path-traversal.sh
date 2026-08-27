#!/usr/bin/env sh
# Security test: discovered-path-add must reject absolute paths, parent
# traversal, and directory-wide paths.
set -eu
for bad in "/etc/passwd" "../evil" "src/" "src/../../evil"; do
  set +e
  sh scripts/discovered-path-add.sh EP-000 WM-SRC-000001 "$bad" "rationale for a bad path that must be rejected" tests/wiremudder/ep000/contract/001-pinned-commit.sh "rollback note" >/tmp/wm-sec-001.out 2>&1
  rc=$?
  set -e
  [ "$rc" -ne 0 ] || { echo "FAIL: accepted bad path $bad" >&2; exit 1; }
done
echo "security path-traversal: ok"
