# WireMudder Shared Performance Test Boundary

Directory: `tests/wiremudder/performance/`

This boundary is the shared home for cross-node performance test material
that is not specific to a single EP milestone. EP-032's per-milestone
performance tests live under `tests/wiremudder/ep032/` (unit, integration,
e2e, failure, security, performance); reusable fixtures and helpers shared
across nodes are recorded here.

Current contents: this index. As the graph proceeds, any performance
fixture, distribution oracle, or regression helper that multiple nodes
must share will be added here with source evidence and a scope-audit-clean
commit, per AGENTS.md anti-drift rules.
