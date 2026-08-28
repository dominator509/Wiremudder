#!/usr/bin/env sh
# EP-025 M1 contract test: every acceptance obligation of the node
# contract must be satisfied by an owning specification or security
# constitution. Fails if an obligation has no binding source.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

CONTRACT=.agent/node-contracts/EP-025.md
SPEC016=.agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md
SPEC004=.agent/specs/SPEC-004-performance-constitution-and-degradation.md

# Acceptance obligation 1: Assets are original or properly licensed.
grep -q "original tile, sprite, diorama" "$SPEC016" || fail "obligation 1 (original assets) has no source"
# Obligation 2: Raw text remains authoritative.
grep -q "Raw text remains visible and authoritative" "$SPEC016" || fail "obligation 2 (text authority) has no source"
# Obligation 3: Visual emits cover the complete catalog.
grep -q "NPCs, mobs, animals" "$SPEC016" || fail "obligation 3 (emit catalog) has no source"
# Obligation 4: Frame budget and drop/coalesce behavior are proven.
grep -q "4-6 ms frame budget" "$SPEC016" || fail "obligation 4 (frame budget) has no source"
grep -q "drop or coalesce" "$SPEC016" || fail "obligation 4 (drop/coalesce) has no source"
# Obligation 5: Static and text fallback work.
grep -q "static" "$SPEC016" || fail "obligation 5 (static fallback) has no source"
grep -q "text-only fallback" "$SPEC016" || fail "obligation 5 (text fallback) has no source"
# Obligation 6: Renderer crash preserves gameplay.
grep -q "preserves text gameplay" "$SPEC016" || fail "obligation 6 (crash preserves gameplay) has no source"

echo "contract EP-025 renderer-obligations: ok"
