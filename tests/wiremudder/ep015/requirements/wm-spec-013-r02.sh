# WM-SPEC-013-R02: context capsules preserve room, exits, entities,
# combat, health, prompt, quest clues, safety evidence, user request
# while removing repetitive spam.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-013-r02: FAIL - $1" >&2; exit 1; }
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example feature_probe -- "WM-FEAT-0048" > /tmp/wm-r02.txt 2>/dev/null || fail "probe"
grep -q "WM-FEAT-0048: ok" /tmp/wm-r02.txt || fail "capsule fields"
# Spam collapse is a crate invariant.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml spam_collapse_bounded >/dev/null 2>&1 \
  || fail "spam collapse"
rm -f /tmp/wm-r02.txt
echo "wm-spec-013-r02: ok"
