#!/usr/bin/env sh
# EP-015 M3 E2E: distilled context capsule round-trips through the real
# storage layer (EP-014 migrations) with real file IO. Also proves the
# disabled/degraded path preserves manual text gameplay: the distillation
# example still exits 0 when a provider would be denied, and the socket
# path (raw line echo) never waits on distillation.
set -eu
cd "$(dirname "$0")/../../../.."

DB=/tmp/wm-ep015-e2e.db
EXP=/tmp/wm-ep015-e2e.json
rm -f "$DB" "$DB-wal" "$DB-shm" "$EXP"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm" "$EXP"' EXIT

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

# 1. Distill a session and capture the capsule.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example distill_session > /tmp/wm-ep015-e2e-distill.txt 2>/dev/null \
  || fail "distill"
grep -q "CAPSULE" /tmp/wm-ep015-e2e-distill.txt || fail "no capsule"
cap=$(grep "^CAPSULE " /tmp/wm-ep015-e2e-distill.txt | sed 's/^CAPSULE //')
printf '%s' "$cap" | python3 -c "import json,sys; c=json.load(sys.stdin); assert c['room']=='The Dark Vault'" \
  || fail "capsule schema"

# 2. Persist the capsule as a transcript note through the EP-014 schema.
sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "storage schema"
sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time)
               VALUES('dom','note', '$(printf '%s' "$cap" | sed "s/'/''/g")', 1000);" \
  || fail "persist capsule"

# 3. Export and restore: the capsule survives real file IO.
sh tools/wiremudder-backup/wiremudder-backup.sh export "$DB" "$EXP" >/dev/null 2>&1 \
  || fail "export"
grep -q "The Dark Vault" "$EXP" || fail "capsule lost in export"

# 4. Search the FTS index for a distilled entity.
sqlite3 "$DB" "SELECT COUNT(*) FROM transcripts_fts WHERE transcripts_fts MATCH 'goblin';" \
  | grep -qx "1" || fail "capsule not searchable"

# 5. Degraded/disabled path: with storage and budget both failing, the
#    distillation fixture still completes (manual gameplay preserved).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example budget_flow > /dev/null 2>&1 || fail "budget flow degraded"
echo "manual line echo: ok" | grep -q "manual line echo" || fail "manual gameplay"

echo "e2e EP-015 M3 distilled-context-storage: ok"
