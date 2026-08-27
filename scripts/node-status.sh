#!/usr/bin/env sh
set -eu
awk '/^GRAPH-TABLE-BEGIN$/{p=1;next} /^GRAPH-TABLE-END$/{p=0} p&&$1=="NODE"{print $2}' .agent/GRAPH.md | while read -r node; do
  printf '%s\t%s\n' "$node" "$(sh scripts/ledger.sh status "$node")"
done
