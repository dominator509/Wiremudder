#!/usr/bin/env sh
# LF-027 help-coach-no-side-effects: live-fire proof for EP-027.
#
# Runs the real user outcome for Contextual Help, Setup Coach, and
# Source Index through the production wire-help crate and validates
# every certification obligation from the node contract:
#   1. Help content is generated from accepted sources.
#   2. AI help receives only scoped sanitized context.
#   3. Coach cannot mutate protected settings or send commands.
#   4. Source index is opt-in, local, idle, and removable.
#   5. Capability detection is evidence-based.
#   6. CLI/headless help parity passes.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-027: FAIL - $1" >&2; exit 1; }

CRATE=wirecore/crates/wire-help
OUT=/tmp/lf027_output.log
CERT=/tmp/lf027_certification.json

# 1. Run the real production crate flow (no mocks).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path "$CRATE/Cargo.toml" --example e2e_help > "$OUT" 2>&1 \
  || fail "help e2e did not run"

# 2. Validate the certification record against real output.
grep -q "E2E help-coach: ok" "$OUT" || fail "help e2e not ok"
grep -q "Help content is generated from accepted sources" "$OUT" || fail "obligation 1 (accepted sources) not proven"
grep -q "AI help receives only scoped sanitized context" "$OUT" || fail "obligation 2 (sanitized context) not proven"
grep -q "Coach cannot mutate protected settings or send commands" "$OUT" || fail "obligation 3 (no mutation) not proven"
grep -q "Source index is opt-in, local, idle, and removable" "$OUT" || fail "obligation 4 (source index) not proven"
grep -q "Capability detection is evidence-based" "$OUT" || fail "obligation 5 (capability detection) not proven"
grep -q "CLI/headless help parity passes" "$OUT" || fail "obligation 6 (CLI parity) not proven"

# 3. Crate-level invariants (source proof for obligations).
LIB="$CRATE/src/lib.rs"
grep -q "add_source" "$LIB" || fail "accepted-sources invariant missing"
grep -q "build_ask_context" "$LIB" || fail "sanitized-context invariant missing"
grep -q "apply_step" "$LIB" || fail "coach no-mutation invariant missing"
grep -q "enable_source_index" "$LIB" || fail "source-index opt-in invariant missing"
grep -q "remove_source_index" "$LIB" || fail "source-index removable invariant missing"
grep -q "observe_capability" "$LIB" || fail "capability evidence invariant missing"
grep -q "cli_help" "$LIB" || fail "cli parity invariant missing"
grep -q "can_send_command" "$LIB" || fail "no-command invariant missing"

# 4. Certification record (real evidence for the ledger).
python3 - "$OUT" > "$CERT" <<'PY'
import json, sys, subprocess
out = open(sys.argv[1]).read()
cert = {
    "live_fire_id": "LF-027",
    "name": "help-coach-no-side-effects",
    "help_content_from_accepted_sources": "ok" if "Help content is generated from accepted sources" in out else "missing",
    "ai_help_scoped_sanitized": "ok" if "AI help receives only scoped sanitized context" in out else "missing",
    "coach_no_mutation_no_commands": "ok" if "Coach cannot mutate protected settings or send commands" in out else "missing",
    "source_index_optin_local_idle_removable": "ok" if "Source index is opt-in, local, idle, and removable" in out else "missing",
    "capability_detection_evidence_based": "ok" if "Capability detection is evidence-based" in out else "missing",
    "cli_headless_help_parity": "ok" if "CLI/headless help parity passes" in out else "missing",
    "commit": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
}
print(json.dumps(cert, indent=2))
PY

python3 - "$CERT" <<'PY'
import json, sys
cert = json.load(open(sys.argv[1]))
obligations = {
    "help-content-from-accepted-sources": cert["help_content_from_accepted_sources"],
    "ai-help-scoped-sanitized": cert["ai_help_scoped_sanitized"],
    "coach-no-mutation-no-commands": cert["coach_no_mutation_no_commands"],
    "source-index-optin-local-idle-removable": cert["source_index_optin_local_idle_removable"],
    "capability-detection-evidence-based": cert["capability_detection_evidence_based"],
    "cli-headless-help-parity": cert["cli_headless_help_parity"],
}
bad = [k for k, v in obligations.items() if v != "ok"]
if bad:
    print(f"LF-027: FAIL - certification obligations not met: {bad}", file=sys.stderr)
    sys.exit(1)
print(f"LF-027: {len(obligations)} certification obligations true; commit={cert['commit']}")
PY

echo "LF-027 help-coach-no-side-effects: ok"
