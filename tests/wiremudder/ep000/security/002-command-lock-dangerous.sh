#!/usr/bin/env sh
# Security test: command-lock-add must reject destructive or multiline
# commands even when the key/platform are valid.
set -eu
for bad in "rm -rf /" "git push --force origin main" "git clean -fdx" $'cmake --preset linux-debug-nosan\nrm -rf /'; do
  set +e
  sh scripts/command-lock-add.sh build WM-SRC-000019 EP-000 linux "$bad" >/tmp/wm-sec-002.out 2>&1
  rc=$?
  set -e
  [ "$rc" -ne 0 ] || { echo "FAIL: accepted dangerous command: $bad" >&2; exit 1; }
done
echo "security command-lock-dangerous: ok"
