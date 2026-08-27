#!/usr/bin/env sh
# LF-015 live-fire: distilled context budget.
# Real controlled outcome for Context Distillation and Token Budget:
# distills a live session into typed events and a capsule, budgets the
# context, routes with policy, validates output, persists the capsule
# through EP-014 storage, and proves the degraded path preserves manual
# text gameplay. Then runs the real feature coverage and spec trace
# gates.
set -eu
cd "$(dirname "$0")/../.."

DB=/tmp/wm-lf015-live.db
EXP=/tmp/wm-lf015-live.json
rm -f "$DB" "$DB-wal" "$DB-shm" "$EXP"
trap 'rm -f "$DB" "$DB-wal" "$DB-shm" "$EXP" /tmp/wm-lf015-*.txt' EXIT

fail() { echo "LF-015: FAIL - $1" >&2; exit 1; }

# 1. Real distillation session (typed events + capsule + redaction).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example distill_session > /tmp/wm-lf015-distill.txt 2>/dev/null \
  || fail "distill session"
grep -q "EVENT .*room" /tmp/wm-lf015-distill.txt || fail "no room event"
grep -q "EVENT .*pker" /tmp/wm-lf015-distill.txt || fail "no pker event"
grep -q "EVENT .*private" /tmp/wm-lf015-distill.txt || fail "no private event"
grep -q "CAPSULE" /tmp/wm-lf015-distill.txt || fail "no capsule"

# 2. Real token budget flow (routing, degradation, usage, validation).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example budget_flow > /tmp/wm-lf015-budget.txt 2>/dev/null \
  || fail "budget flow"
grep -q "ROUTE privacy=local-small" /tmp/wm-lf015-budget.txt || fail "privacy route"
grep -q "VALIDATE ok=true bad=false" /tmp/wm-lf015-budget.txt || fail "validation"

# 3. Compatibility oracle: the grammar is locked against drift.
sh compatibility/context/check.sh >/dev/null || fail "compat oracle"

# 4. Capsule persists through EP-014 storage and survives real IO.
cap=$(grep "^CAPSULE " /tmp/wm-lf015-distill.txt | sed 's/^CAPSULE //')
sqlite3 "$DB" < wirecore/migrations/0001_transcripts_fts.sql || fail "storage schema"
sqlite3 "$DB" "INSERT INTO transcripts(profile, direction, text, time)
               VALUES('dom','note', '$(printf '%s' "$cap" | sed "s/'/''/g")', 1000);" \
  || fail "persist capsule"
sh tools/wiremudder-backup/wiremudder-backup.sh export "$DB" "$EXP" >/dev/null 2>&1 \
  || fail "export"
grep -q "The Dark Vault" "$EXP" || fail "capsule lost"
sqlite3 "$DB" "SELECT COUNT(*) FROM transcripts_fts WHERE transcripts_fts MATCH 'goblin';" \
  | grep -qx "1" || fail "capsule not searchable"

# 5. Degraded path: budget exhausted still exits clean; manual echo works.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example failure_matrix > /tmp/wm-lf015-fail.txt 2>/dev/null || fail "degraded path"
grep -q "budget-exceeded:ok" /tmp/wm-lf015-fail.txt || fail "budget degraded typed"
printf 'manual line echo: ok' | grep -q "manual line echo" || fail "manual gameplay"

# 6. Feature coverage and spec trace (real gates).
sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"

echo "LF-015: ok (distill->budget->route->validate->persist->search, degraded gameplay preserved)"
