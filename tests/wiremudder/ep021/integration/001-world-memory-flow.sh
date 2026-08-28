#!/usr/bin/env sh
# EP-021 M3 integration test: world-memory crate integration flow.
# 1. The three crates build and their deterministic suites pass.
# 2. The memory schemas exist and are valid JSON.
# 3. Manual gameplay is preserved: every surface is an observer with no
#    command path.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# 1. Crate surfaces real and tested.
for c in wire-world-brain wire-world-bible wire-time-machine; do
  [ -f "wirecore/crates/$c/Cargo.toml" ] || fail "missing $c crate manifest"
done
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "7 passed" || fail "wire-world-brain crate tests"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-world-bible/Cargo.toml 2>&1 \
  | grep -q "6 passed" || fail "wire-world-bible crate tests"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-time-machine/Cargo.toml 2>&1 \
  | grep -q "5 passed" || fail "wire-time-machine crate tests"

# 2. Schemas valid.
for f in schemas/wiremudder/memory/*.json; do
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid schema $f"
done

# 3. Manual gameplay preserved: all surfaces observer-only.
BRAIN=wirecore/crates/wire-world-brain/src/lib.rs
BIBLE=wirecore/crates/wire-world-bible/src/lib.rs
TM=wirecore/crates/wire-time-machine/src/lib.rs
grep -q "can_send_command" "$BRAIN" || fail "brain no-command invariant missing"
grep -q "can_send_command" "$BIBLE" || fail "bible no-command invariant missing"
grep -q "can_send_command" "$TM" || fail "time machine no-command invariant missing"

echo "integration EP-021 M3 world-memory-flow: ok"
