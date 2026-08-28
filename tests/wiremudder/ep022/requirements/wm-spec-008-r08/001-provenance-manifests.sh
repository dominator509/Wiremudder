#!/usr/bin/env sh
# WM-SPEC-008-R08: world packs, command packs, trigger/macro packs,
# themes, renderer packs, soundscape packs, Soul templates, and help
# indexes use signed or user-local provenance-aware manifests. EP-022
# owns the trigger/macro pack surface: Macro Forge drafts carry
# provenance (id, kind, created_at_ms) and preview/approval authority.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
grep -q "pub struct AutomationDraft" "$LIB" || fail "AutomationDraft missing"
grep -q "created_at_ms" "$LIB" || fail "drafts lack provenance timestamp"
grep -q "pub approved" "$LIB" || fail "drafts lack approval state"
grep -q "pub preview_only" "$LIB" || fail "drafts lack preview state"
echo "requirement WM-SPEC-008-R08 provenance-manifests: ok"
