# WireMudder Feature Flags

Feature flags are typed, profile-scoped where appropriate, auditable, and cannot grant permissions or bypass policy. Every optional subsystem has `disabled`, `observe`, `suggest`, or its smallest applicable mode before any action-capable mode. A replacement flag retains the inherited implementation as fallback through at least one stable release.

A flag cannot hide demo behavior or mark an uncertified provider as available. Release manifests list enabled, disabled, and blocked capability IDs.
