#!/usr/bin/env sh
# E2E test: the complete boot gate chain must pass against the live
# repository state — blueprint validation, preflight, graph dispatch,
# contract, and node verifier for EP-000.
set -eu
out=$(sh scripts/validate-blueprint.sh 2>&1) || { echo "FAIL: validate-blueprint" >&2; exit 1; }
echo "$out" | grep -q "blueprint validation: ok" || { echo "FAIL: blueprint sentinel missing" >&2; exit 1; }
out=$(sh scripts/preflight.sh 2>&1) || { echo "FAIL: preflight" >&2; exit 1; }
echo "$out" | grep -q "preflight: ok" || { echo "FAIL: preflight sentinel missing" >&2; exit 1; }
dispatch=$(sh scripts/graph-next.sh)
case "$dispatch" in
  "NEXT EP-"[0-9][0-9][0-9]|"RESUME EP-"[0-9][0-9][0-9]|"BLOCKED EP-"[0-9][0-9][0-9]|ALL_DONE) ;;
  *) echo "FAIL: unexpected dispatch $dispatch" >&2; exit 1 ;;
esac
sh scripts/node-contract-check.sh EP-000 >/dev/null || { echo "FAIL: contract check" >&2; exit 1; }
echo "e2e boot-gate-chain: ok"
