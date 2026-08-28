#!/usr/bin/env sh
# EP-037 M3 integration test: the package-author guide documents real
# oracle commands; this test runs those exact commands against the real
# wire-packages oracle and confirms the documented outputs match reality.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"
oracle="cargo run --quiet --release --manifest-path wirecore/crates/wire-packages/Cargo.toml --bin wire-packages-oracle --"

# 1. Docs claim: decisions "" "network,secrets,command_send" -> all denied,
#    expansion = all three. Run the real command and compare.
out=$($oracle decisions "" "network,secrets,command_send" 2>&1)
echo "$out" | grep -q '"permission":"network","decision":"denied"' || fail "network not denied"
echo "$out" | grep -q '"permission":"secrets","decision":"denied"' || fail "secrets not denied"
echo "$out" | grep -q '"permission":"command_send","decision":"denied"' || fail "command_send not denied"
echo "$out" | grep -q '"expansion":\["network","secrets","command_send"\]' || fail "expansion wrong"

# 2. Docs claim: decisions "network" "network,secrets,command_send" ->
#    network granted, secrets+command_send denied, expansion = those two.
out2=$($oracle decisions "network" "network,secrets,command_send" 2>&1)
echo "$out2" | grep -q '"permission":"network","decision":"granted"' || fail "network not granted"
echo "$out2" | grep -q '"permission":"secrets","decision":"denied"' || fail "secrets not denied"
echo "$out2" | grep -q '"permission":"command_send","decision":"denied"' || fail "command_send not denied"

# 3. Docs claim: hash match -> {"hash":"verified"}, mismatch -> {"hash":"mismatch"}.
h1=$($oracle hash "ABC123" "abc123" 2>&1)
echo "$h1" | grep -q '{"hash":"verified"}' || fail "hash match not verified"
h2=$($oracle hash "ABC123" "XYZ999" 2>&1)
echo "$h2" | grep -q '{"hash":"mismatch"}' || fail "hash mismatch not detected"

echo "integration EP-037 package-author-oracle: ok"
