# Node-Scoped Preflight

Baseline preflight intentionally excludes optional provider and publication credentials. An owning node copies its environment example, obtains the least-privilege test credential when the selected release profile requires certification, runs a read-only probe, and records certification evidence. Missing optional credentials keep the adapter disabled.

Signing keys are never represented here.
