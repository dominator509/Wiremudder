#!/usr/bin/env sh
# EP-027 M2 unit test: wire-help crate must compile and all
# deterministic unit tests must pass.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

cd wirecore/crates/wire-help

CARGO_TARGET_DIR="$OLDPWD/wirecore/target" "$cargo_bin" test --quiet 2>&1 | tee /tmp/ep027_unit_test.log
grep -q "test result: ok" /tmp/ep027_unit_test.log || fail "crate tests did not pass"
grep -q "27 passed" /tmp/ep027_unit_test.log || fail "expected 27 passing tests"

# Deterministic invariants must exist in the crate source.
grep -q "index_reproducible" src/lib.rs || fail "missing reproducibility test"
grep -q "answer_reports_stale_source" src/lib.rs || fail "missing stale-source test"
grep -q "ask_context_redacts_secrets" src/lib.rs || fail "missing secret-redaction test"
grep -q "coach_proposes_without_mutation" src/lib.rs || fail "missing coach no-mutation test"
grep -q "source_index_secret_aware" src/lib.rs || fail "missing source-index secret test"
grep -q "capability_detection_requires_evidence" src/lib.rs || fail "missing capability evidence test"
grep -q "cli_parity_with_ui" src/lib.rs || fail "missing CLI parity test"
grep -q "cannot_send_commands" src/lib.rs || fail "missing no-command test"

echo "unit EP-027 wire-help: ok"
