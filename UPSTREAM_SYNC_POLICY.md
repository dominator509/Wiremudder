# Upstream Synchronization Policy

## Remotes

- `upstream` points to `https://github.com/Mudlet/Mudlet.git`.
- `origin` points to the WireMudder repository supplied by the operator.
- The pinned baseline is recorded in `UPSTREAM.lock.yaml`.

## Sync Flow

1. Fetch upstream without changing the active branch.
2. Create `sync/upstream-YYYYMMDD-SHORTSHA` from the last green WireMudder tag.
3. Record old and new upstream SHAs in source evidence.
4. Merge the upstream development commit; do not flatten history.
5. Resolve only evidence-backed conflicts.
6. Run inherited baseline, compatibility oracle, schema, security, performance, platform, package, import, and installer gates.
7. Classify WireMudder patches that conflict repeatedly and redesign them toward narrower adapters.
8. Merge the sync branch only when its node or maintenance ExecPlan is green.
9. Preserve the previous release tag and rollback instructions.

## Patch Classes

`UPSTREAMABLE`, `WIREMUDDER_BRIDGE`, `WIREMUDDER_FEATURE`, `WIREMUDDER_BRANDING`, `SECURITY_HARDENING`, and `GRAPHLOCK_GOVERNANCE` are the only classes. Review templates require one class per logical patch.

## Forbidden Sync Practices

No forced push, history rewrite, unreviewed generated file replacement, broad formatting pass, mass rename, silent submodule advance, or acceptance of a red compatibility diff.
