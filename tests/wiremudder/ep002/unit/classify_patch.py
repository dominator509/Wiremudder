#!/usr/bin/env python3
"""Classify WireMudder changes by patch type (SPEC-001-R04).

Categories: upstreamable, bridge, feature, branding, security,
graphlock. A change is classified by its paths and message; unknown or
mixed changes classify as 'unclassified' (fail-closed).

Usage: classify_patch.py PATH_OR_RANGE [MESSAGE]
Example: classify_patch.py HEAD~1..HEAD "[EP-002][M2] ..."
"""
from __future__ import annotations
import subprocess, sys
from pathlib import Path

CATEGORIES = {
    'upstreamable': ('Generic fixes prepared for upstream contribution.'),
    'bridge': ('WireCore bridge, IPC, headless contracts.'),
    'feature': ('New WireMudder capability.'),
    'branding': ('Branding metadata, names, assets.'),
    'security': ('Security hardening, secrets, permissions.'),
    'graphlock': ('Graphlock governance, control plane, evidence.'),
}

PATH_RULES = [
    ('graphlock', ('.agent/', 'AGENTS.md', 'CLAUDE.md', 'COMMANDS.md',
                   '.github/copilot-instructions.md', 'docs/upstream/',
                   'docs/wiremudder/upstream/', 'UPSTREAM.lock.yaml',
                   'UPSTREAM_SYNC_POLICY.md', 'BRANDING_POLICY.md',
                   'LICENSE_STRATEGY.md', 'scripts/')),
    ('bridge', ('wirecore/', 'src/wiremudder/', 'schemas/wiremudder/',
                'docs/wiremudder/bridge/')),
    ('branding', ('branding/', 'docs/wiremudder/branding/')),
    ('security', ('docs/wiremudder/security/', 'tests/wiremudder/*/security/',
                  'WIREMUDDER_SECURITY.md')),
    ('feature', ('docs/wiremudder/', 'tests/wiremudder/', 'src/wiremudder/')),
]


def classify(paths: list[str], message: str) -> str:
    msg = message.lower()
    if any(k in msg for k in ('[security]', 'cve', 'credential', 'secret', 'permission')):
        return 'security'
    if any(k in msg for k in ('[graphlock]', '[6layer]', 'ledger', 'governance')):
        return 'graphlock'
    if any(k in msg for k in ('[branding]', 'brand')):
        return 'branding'
    if any(k in msg for k in ('[bridge]', 'wirecore', 'ipc')):
        return 'bridge'
    if any(k in msg for k in ('[feature]', 'feat')):
        return 'feature'
    if any(k in msg for k in ('[upstream]', 'upstreamable', 'cherry-pick', 'sync')):
        return 'upstreamable'
    # Path-based fallback: choose the dominant matching category.
    best = 'unclassified'
    best_count = 0
    for category, prefixes in PATH_RULES:
        count = 0
        for p in paths:
            if any(p.startswith(prefix.rstrip('/')) or p == prefix.rstrip('/')
                   for prefix in prefixes):
                count += 1
        if count > best_count:
            best = category
            best_count = count
    if best_count > 0:
        return best
    return 'unclassified'


def changed_paths(rev_range: str) -> list[str]:
    # Range form (A..B) or commit form both supported.
    proc = subprocess.run(
        ['git', 'diff', '--name-only', rev_range],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    )
    paths = [line for line in proc.stdout.splitlines() if line.strip()]
    if paths:
        return paths
    proc = subprocess.run(
        ['git', 'show', '--name-only', '--format=', rev_range],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    )
    return [line for line in proc.stdout.splitlines() if line.strip()]


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('usage: classify_patch.py PATH_OR_RANGE [MESSAGE]', file=sys.stderr)
        raise SystemExit(2)
    rev = sys.argv[1]
    message = sys.argv[2] if len(sys.argv) > 2 else ''
    paths = changed_paths(rev)
    if not paths:
        print('unclassified')
        raise SystemExit(0)
    print(classify(paths, message))
