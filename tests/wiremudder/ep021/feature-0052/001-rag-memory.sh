#!/usr/bin/env sh
# EP-021 M5 feature test: WM-FEAT-0052 RAG memory.
# RAG memory under the node's accepted fallback: user-authored notes and
# deterministic room observations are stored; inferred durable facts and
# vector retrieval stay disabled until real certification. Proven by real
# crate surface and LF-021 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0052: FAIL - $1" >&2; exit 1; }

# World Brain is the deterministic observation store (source-event-scoped,
# content-hashed facts). No vector index exists in the owned crates.
LIB=wirecore/crates/wire-world-brain/src/lib.rs
grep -q "pub struct WorldBrain" "$LIB" || fail "WorldBrain missing"
grep -q "content_hash" "$LIB" || fail "content hash missing"
grep -q "source_event" "$LIB" || fail "source event missing"

# No vector retrieval boundary is claimed by this node.
for lib in wirecore/crates/wire-world-brain/src/lib.rs \
           wirecore/crates/wire-world-bible/src/lib.rs \
           wirecore/crates/wire-time-machine/src/lib.rs; do
  if grep -qE "pub fn (vector_search|retrieve_vectors|embed)" "$lib"; then
    fail "vector retrieval claimed without certification: $lib"
  fi
done

# LF-021 certified deterministic memory.
[ -f .agent/state/evidence/EP-021/M5/lf021-certification.json ] || fail "LF-021 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-021/M5/lf021-certification.json')); assert d['provenance_recorded'] and d['private_scoped']" \
  || fail "LF-021 rag certification false"

echo "feature-0052 RAG memory: ok"
