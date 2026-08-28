//! WireMudder security core (EP-033).
//!
//! Implements the deterministic core rules behind the Security, Threat Model,
//! License, SBOM, and Supply Chain node contract:
//!
//! - `ThreatModel` — data flow, assets, actors, entry points, trust
//!   boundaries, misuse cases, mitigations, residual risk, verification
//!   (SPEC-022-R08).
//! - `SecretsScanner` — deterministic scan for secret-shaped material that
//!   must never be committed or logged (SPEC-022-R02).
//! - `PromptInjectionGuard` — fail-closed detection of prompt-injection
//!   attempts on untrusted input (SPEC-022-R04).
//! - `SupplyChainInventory` — provenance inventory of source, dependency,
//!   submodule, binary, model, voice, audio, visual, package, installer, and
//!   update components (SPEC-022-R06, SPEC-001-R08).
//! - `SbomBuilder` — reproducible SBOM with hashes and license inventory
//!   (SPEC-020-R03).
//! - `LicenseInventory` — GPL/source obligation inventory (SPEC-001-R08,
//!   SPEC-020-R03).
//! - `UpdateLane` — the separate update lanes (SPEC-020-R02) and optional
//!   asset policy (SPEC-020-R08).
//! - `ReleaseBlocker` — critical findings block release (SPEC-028-R03).
//!
//! All rules are deterministic, fail closed, and never weakened for speed.

pub mod injection;
pub mod inventory;
pub mod lanes;
pub mod licenses;
pub mod release;
pub mod sbom;
pub mod secrets;
pub mod threat;

pub use injection::PromptInjectionGuard;
pub use inventory::SupplyChainInventory;
pub use lanes::UpdateLane;
pub use licenses::LicenseInventory;
pub use release::ReleaseBlocker;
pub use sbom::SbomBuilder;
pub use secrets::SecretsScanner;
pub use threat::ThreatModel;
