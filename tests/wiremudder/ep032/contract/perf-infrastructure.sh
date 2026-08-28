#!/usr/bin/env sh
# EP-032 M1 contract test: the benchmark infrastructure this node must
# orchestrate exists across the owned crates — the per-crate perf example
# pattern that M2/M3 benchmarks will drive reproducibly.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

# The per-crate perf fixture pattern exists across owned subsystems.
for ex in \
  wirecore/crates/wire-renderer/examples/perf_fixture.rs \
  wirecore/crates/wire-voice/examples/perf_fixture.rs \
  wirecore/crates/wire-replay/examples/perf_fixture.rs \
  wirecore/crates/wire-import/examples/perf_fixture.rs \
  wirecore/crates/wire-bug-automation/examples/perf_fixture.rs \
  wirecore/crates/wire-soundscape/examples/perf_fixture.rs; do
  [ -f "$ex" ] || fail "missing perf fixture $ex"
done

# The crates build (fixtures compile with the workspace).
for c in wire-renderer wire-voice wire-replay wire-import; do
  [ -f "wirecore/crates/$c/Cargo.toml" ] || fail "missing crate $c"
done

echo "contract EP-032 perf-infrastructure: ok"
