#!/usr/bin/env sh
# Performance test: schema validation and manifest generation are bounded.
set -eu
start=$(date +%s%N)
for i in 1 2 3 4 5; do
  python3 tools/schema-bindings/generate_bindings.py >/dev/null
done
end=$(date +%s%N)
ms=$(( (end - start) / 1000000 ))
echo "performance schema-bindings-5x: ${ms}ms"
[ "$ms" -lt 15000 ] || { echo "FAIL: schema generation too slow" >&2; exit 1; }
echo "performance schema-bindings: ok"
