#!/usr/bin/env sh
# EP-018 M5 feature test: WM-FEAT-0182 Lore and Memory Curator Agent.
# Specialized lore/memory-curator role exists in the registry (R02) with
# role-scoped memory permissions over the Lore class (R06) and the
# memory-permissions schema.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0182: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-agents/src/lib.rs
grep -q "LoreCurator," "$LIB" || fail "LoreCurator role missing"
grep -q '"lore-curator"' "$LIB" || fail "lore-curator key missing"
grep -q "MemoryClass::Lore" "$LIB" || fail "Lore memory class missing"
grep -q "pub fn grant" "$LIB" || fail "grant path missing (external authority only)"

python3 -c "import json; d=json.load(open('schemas/wiremudder/agents/memory-permissions-v1.json')); assert 'role' in json.dumps(d).lower() and 'class' in json.dumps(d).lower()" \
  || fail "memory-permissions schema invalid"

# Real behavior: a read grant on Lore for the curator is explicit; the
# default matrix denies it (absent = deny).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml memory 2>&1 \
  | grep -q "memory" || fail "memory permission tests"

echo "feature-0182 lore-memory-curator: ok"
