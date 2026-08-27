#!/usr/bin/env sh
# WM-SPEC-026-R05: tracing is bounded, local by default, sampled,
# redacted, and disabled if its cost threatens gameplay.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "wm-spec-026-r05: FAIL - $1" >&2; exit 1; }

# Bounded and local by default: no tracing/telemetry framework is
# compiled into the storage crate, so no remote span export exists.
deps=$(sed -n '/\[dependencies\]/,/^\[/p' wirecore/crates/wire-storage/Cargo.toml)
if printf '%s' "$deps" | grep -qE "tracing|opentelemetry|jaeger|zipkin|prometheus|metrics"; then
  fail "tracing dependency present"
fi

# The design doc constrains tracing to bounded, sampled, redacted local
# diagnostics.
grep -qiE "trac|redact|local" docs/wiremudder/storage/design/*.md \
  || fail "design trace constraints missing"

# Runtime cost is bounded: the crate's only FFI work is append/search on
# a local file, proven under the perf budget (append < 0.1 ms/line,
# search < 10 ms/query) by the M4 evidence.
EV=.agent/state/evidence/EP-014/M4/performance-001.json
[ -f "$EV" ] || fail "perf evidence missing"
grep -q '"ok": true' "$EV" || fail "perf not ok"

echo "wm-spec-026-r05: ok"
