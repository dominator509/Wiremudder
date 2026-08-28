#!/usr/bin/env sh
# EP-038 M4 performance fixture: real wall-clock cost of the release
# candidate gates on this host. The compiled release oracle is invoked
# directly (no cargo-spawn overhead). This is an operations-class gate
# (SPEC-004 P4), not the manual gameplay path.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || fail "oracle binary missing"

cand=release/wiremudder/candidate
work=$(mktemp -d /tmp/ep038_perf_XXXX)
trap 'rm -rf "$work"' EXIT

# Hardware and workload context (real, recorded into the fixture log).
{
  echo "host: $(uname -m) $(nproc) cores"
  echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "binary: $(stat -c %s "$oracle") bytes"
} > "$work/context.txt"
cat "$work/context.txt"

# 1. candidate-check latency: 30 real invocations.
n=30
samples="$work/samples.txt"
i=1
while [ "$i" -le "$n" ]; do
  start=$(date +%s%N)
  "$oracle" candidate-check "$cand/manifest.json" >/dev/null 2>&1
  end=$(date +%s%N)
  echo $(( (end - start) / 1000 )) >> "$samples"
  i=$((i + 1))
done

# 2. Distribution (microseconds).
sort -n "$samples" -o "$samples"
total=$(awk '{s+=$1} END {print s}' "$samples")
count=$(wc -l < "$samples")
mean=$(( total / count ))
p50=$(sed -n "$(( (count + 1) / 2 ))p" "$samples")
p95=$(sed -n "$(( (count * 95 + 99) / 100 ))p" "$samples")
p99=$(sed -n "$(( (count * 99 + 99) / 100 ))p" "$samples")
max=$(tail -n 1 "$samples")
echo "candidate-check us: mean=$mean p50=$p50 p95=$p95 p99=$p99 max=$max"

# SPEC-004 P4 budget for operations gates: 100ms. Fail closed if exceeded.
budget=100000
if [ "$p95" -gt "$budget" ]; then
  fail "p95 $p95us exceeds P4 budget ${budget}us"
fi

# 3. Checksum sweep latency: full SHA256SUMS verify, 3 runs, report max.
chk_max=0
r=1
while [ "$r" -le 3 ]; do
  start=$(date +%s%N)
  (cd "$cand" && sha256sum -c SHA256SUMS >/dev/null 2>&1)
  end=$(date +%s%N)
  ms=$(( (end - start) / 1000000 ))
  [ "$ms" -gt "$chk_max" ] && chk_max=$ms
  r=$((r + 1))
done
echo "checksum sweep (9 artifacts, 296MB): max=${chk_max}ms"

# 4. Persist raw evidence for the node's release-evidence boundary.
cp "$samples" .agent/state/release-evidence/perf-candidate-check-us.txt
cp "$work/context.txt" .agent/state/release-evidence/perf-context.txt
{
  echo "mean_us=$mean p50_us=$p50 p95_us=$p95 p99_us=$p99 max_us=$max"
  echo "checksum_sweep_max_ms=$chk_max"
  echo "budget_us=$budget"
} > .agent/state/release-evidence/perf-summary.txt
echo "performance: raw evidence written to .agent/state/release-evidence/"

echo "performance EP-038 release-candidate-gates: ok"
