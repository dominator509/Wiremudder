# Package Operations (EP-010 M4)

## Health

- Rust core: `CARGO_TARGET_DIR=wirecore/target /root/.cargo/bin/cargo test
  --manifest-path wirecore/crates/wire-packages/Cargo.toml`
- Oracle: `wirecore/target/debug/wire-packages-oracle decisions <approved> <requested>`
- Boundary compile: `tests/wiremudder/ep010/unit/002-package-boundary-cpp.sh`

## Readiness

Package layer is ready when the Rust core tests pass, the C++ boundary
compiles, and `tests/wiremudder/ep010/e2e/001-sandbox-flow.sh` is green.

## Disable

The package layer is additive and optional. Removing
`src/wiremudder/packages/`, `wirecore/crates/wire-packages/`,
`schemas/wiremudder/packages/`, and `compatibility/packages/` disables it.
Manual gameplay never depends on it.

## Recovery

- Firewall misconfiguration: reset the firewall by rebuilding approvals;
  default is deny.
- Quarantine false positive: release the hook id via `Quarantine::release`.
- Hash mismatch: reject the package; never bypass hash verification.

## Backup and Restore

All package artifacts are version-controlled. Restore from git.

## Upgrade

Adding a permission category requires schema, boundary header, Rust enum,
and unit test updates together (lockstep).

## Rollback

Revert the milestone commit. The layer has no runtime state that
survives process exit; rollback is clean.

## Measured Baseline (2026-08-27)

See `.agent/state/evidence/EP-010/M4/firewall-latency.json` for
per-decision latency (in-process C++ boundary, O2). Budget: 10 ms per
decision (P4 package-check path).
