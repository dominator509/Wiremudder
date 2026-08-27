# Authority Change Protocol

## Purpose

The authority hash ledger makes accepted control, specification, graph, execution-prefix, and verification files tamper-evident. A coding executor may update only declared runtime state and the mutable suffix of an ExecPlan beginning at `# 11. Progress`.

## Ordinary Executor Rule

An executor must never regenerate `.agent/AUTHORITY_FILES.tsv`, edit an accepted specification to fit code, alter an expected-path fence after implementation begins, weaken a test or gate, or change an ExecPlan milestone contract. A mismatch is a STOP condition or `NODE_BLOCKED`, not permission to refresh hashes.

## Authorized Change

A material product or architecture change requires a maintainer-controlled blueprint regeneration outside the active graph run. The regeneration records the explicit requirement change, updates affected specifications, feature and requirement ledgers, graph dependencies, node contracts, tests, proofs, risks, rollback, source coverage, and authority hashes as one reviewed artifact. The prior pack remains archived by checksum.

## Mutable Runtime Areas

The append-only ledger, evidence directories, source-evidence ledger, command lock, leases, release evidence, discovered-path JSON rows, generated node verifiers, live-fire scripts, and ExecPlan sections 11 through 14 are runtime state or node outputs. Their validity is governed by dedicated schemas, scope fences, evidence hashes, and node gates rather than the authority ledger.
