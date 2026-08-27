#!/usr/bin/env sh
# Contract test: new WireMudder code is namespaced under the authorized
# boundaries (no top-level product code introduced).
set -eu
python3 - <<'PY' || { echo "FAIL: namespace drift" >&2; exit 1; }
import subprocess
from pathlib import Path
# All tracked files introduced by the bootstrap + EP-000/EP-001 commits
# must live under Graphlock/namespaced boundaries, with inherited files
# only from the upstream baseline.
allowed_prefixes = (
    '.agent/', '.clinerules/', '.cursor/', 'docs/adr/', 'docs/provenance/',
    'docs/upstream/', 'docs/wiremudder/', 'scripts/', 'schemas/wiremudder/',
    'src/wiremudder/', 'tests/wiremudder/', 'tests/live-fire/', 'wirecore/',
    'AGENTS.md', 'CLAUDE.md', 'COMMANDS.md', '.github/copilot-instructions.md',
    '.gitignore', '.env.example', 'ARCHITECTURE.md', 'ASSUMPTIONS.md',
    'AUTHORITY_CHANGE_PROTOCOL.md', 'AUTO_UPDATE_ARCHITECTURE.md',
    'BRANDING_POLICY.md', 'BUG_AUTOMATION_PIPELINE.md', 'CAPABILITY_TAXONOMY.md',
    'COMPATIBILITY_ORACLE.md', 'CONTRIBUTING.md', 'DATA_MODEL.md', 'DECISIONS.md',
    'DEPLOYMENT.md', 'ENVIRONMENT.md', 'ERROR_CATALOG.md', 'EVENT_CATALOG.md',
    'FEATURE_CATALOG.md', 'FEATURE_FLAGS.md', 'GEMINI.md', 'GRAPHLOCK_ADAPTATION.md',
    'HERMES.md', 'HOW_TO_USE.md', 'KNOWN_RISKS.md', 'LICENSE_STRATEGY.md',
    'OBSERVABILITY.md', 'OPENCLAW.md', 'OPERATIONS.md', 'PERFORMANCE_CONSTITUTION.md',
    'PLATFORM_CERTIFICATION.md', 'PREFLIGHT.md', 'PRIVACY_MODEL.md',
    'PRODUCTION_READINESS.md', 'PROJECT_BRIEF.md', 'PROVIDER_CERTIFICATION.md',
    'RELEASE.md', 'RELEASE_PROFILES.md', 'ROADMAP.md', 'ROLLBACK.md',
    'SOURCE_INPUTS.md', 'TESTING.md', 'UPSTREAM.lock.yaml',
    'UPSTREAM_COLLISION_POLICY.md', 'UPSTREAM_SYNC_POLICY.md',
    'WIREMUDDER_GRAPHLOCK_README.md', 'WIREMUDDER_SECURITY.md',
    'PACK_SHA256SUMS.txt',
)
base = '77086c295f4adf59197e586e689d19bdde8e1008'
new_files = subprocess.run(
    ['git','diff','--name-only',base+'..HEAD'], text=True, stdout=subprocess.PIPE
).stdout.splitlines()
bad = []
for f in new_files:
    if not f:
        continue
    if any(f == p or f.startswith(p) for p in allowed_prefixes):
        continue
    bad.append(f)
assert not bad, f'non-namespaced new files: {bad}'
print(f'contract namespacing: ok new_files={len(new_files)}')
PY
echo "contract namespacing: ok"
