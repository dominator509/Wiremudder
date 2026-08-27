# WM-SPEC-013-R01: deterministic parsers produce typed events first;
# AI extraction is a bounded second pass only when rules cannot resolve.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-013-r01: FAIL - $1" >&2; exit 1; }
# Deterministic parse of a known line yields exactly the typed event.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example feature_probe -- "WM-FEAT-0196" > /tmp/wm-r01.txt 2>/dev/null || fail "probe"
grep -q "WM-FEAT-0196: ok" /tmp/wm-r01.txt || fail "typed event"
# Corpus oracle proves determinism (same line, same events, no AI).
sh compatibility/context/check.sh >/dev/null || fail "corpus"
# No AI extraction exists in the crate: no provider/HTTP dependency.
grep -qE "reqwest|tokio|hyper" wirecore/crates/wire-context/Cargo.toml && fail "AI dep present"
rm -f /tmp/wm-r01.txt
echo "wm-spec-013-r01: ok"
