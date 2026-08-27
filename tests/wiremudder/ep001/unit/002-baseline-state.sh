#!/usr/bin/env sh
# Unit test: baseline state directory records the inherited build facts.
set -eu
[ -d .agent/state/baseline ] || { echo "FAIL: baseline state dir missing" >&2; exit 1; }
[ -f .agent/state/baseline/toolchain.lock.tsv ] || { echo "FAIL: toolchain.lock.tsv missing" >&2; exit 1; }
awk -F'\t' 'NR>1 && NF>=3 {print $1}' .agent/state/baseline/toolchain.lock.tsv | grep -qE "cmake|ninja|gcc|lua" || { echo "FAIL: toolchain.lock.tsv lacks core tools" >&2; exit 1; }
echo "unit baseline-state: ok"
