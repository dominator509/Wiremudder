#!/usr/bin/env sh
set -eu
[ "$#" -eq 1 ] || { echo 'usage: node-contract-check.sh EP-XXX' >&2; exit 2; }
exec python3 scripts/node_contract_check.py "$1"
