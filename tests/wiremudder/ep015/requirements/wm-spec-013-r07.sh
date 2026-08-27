# WM-SPEC-013-R07: Token Budget Dashboard records provider, model
# family, feature, context tokens, output tokens, estimated cost,
# latency, cache status, reason, and profile scope.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-013-r07: FAIL - $1" >&2; exit 1; }
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example feature_probe -- "WM-FEAT-0049" > /tmp/wm-r07.txt 2>/dev/null || fail "probe"
grep -q "WM-FEAT-0049: ok" /tmp/wm-r07.txt || fail "dashboard"
# Usage record schema carries every required field.
grep -q "provider" schemas/wiremudder/context/usage-v1.json || fail "provider field"
grep -q "model_family" schemas/wiremudder/context/usage-v1.json || fail "model field"
grep -q "profile_scope" schemas/wiremudder/context/usage-v1.json || fail "profile field"
rm -f /tmp/wm-r07.txt
echo "wm-spec-013-r07: ok"
