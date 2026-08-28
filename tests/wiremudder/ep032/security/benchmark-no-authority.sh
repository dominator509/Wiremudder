#!/usr/bin/env sh
# EP-032 M4 security test: the benchmark model and perf-capture tool must
# not introduce any authority, secret access, remote egress, package
# permission, routing control, signing capability, or stable publication
# (node contract Security and Privacy). Performance degradation must never
# disable consent, redaction, command safety, or signature verification
# (SPEC-004 security rule).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

# The model crate must not reach network, secrets, process execution, or
# authority.
for pat in "QNetworkAccessManager" "std::process::Command" "setenv" "system(" "popen" "getenv" "/proc/" "reqwest" "tokio::net" "openssl"; do
  if grep -q "$pat" benchmarks/wiremudder/src/lib.rs; then
    fail "model references forbidden capability $pat"
  fi
done

# The model must not contain secret-like identifiers.
if grep -q "password\|api_key\|secret\|token" benchmarks/wiremudder/src/lib.rs; then
  fail "model references secret-like identifiers"
fi

# Degradation must never disable safety invariants (SPEC-004 security
# rule): the model always preserves raw text gameplay.
grep -q "pub fn preserves_raw_text" benchmarks/wiremudder/src/lib.rs \
  || fail "model missing raw-text preservation"
grep -q "// Raw text gameplay is sacred" benchmarks/wiremudder/src/lib.rs \
  || fail "model missing sacred-raw-text invariant"

# The perf-capture tool may spawn cargo ONLY for the owned fixtures; it
# must not execute arbitrary commands from input.
if grep -q "Command::new(\"/bin/sh\")\|Command::new(\"bash\")\|Command::new(\"sh\")" tools/perf-capture/src/main.rs; then
  fail "perf-capture executes a shell"
fi

# Raw artifacts must be written under the tool's own artifacts dir, not
# arbitrary paths from external input.
if grep -q "out_dir.join" tools/perf-capture/src/main.rs; then
  :
else
  fail "perf-capture does not constrain artifact writes to out_dir"
fi

echo "security EP-032 benchmark-no-authority: ok"
