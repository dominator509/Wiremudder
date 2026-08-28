# Privacy

WireMudder is a local-first client. Your data stays on your machine unless
you explicitly choose otherwise.

## What Stays Local

- Profiles, worlds, triggers, aliases, timers, macros, maps, packages, and
  settings live in your profile directory.
- Scrollback, logs, and diagnostics are local by default.
- No hosted account is required for the core release (SPEC-000-R09).

## What Leaves Your Machine

- **Nothing by default.** There is no hosted telemetry, crash reporting, or
  analytics endpoint required for core operation (SPEC-026-R08).
- Optional AI providers, voice providers, and external services are used
  only when you configure them and grant the relevant permission.
- Any external observability requires explicit configuration and a privacy
  policy (SPEC-026-R09).

## Exports

User-owned data is exportable. The transcript and world exports are
available from the profile menu (WM-FEAT-0140).

## Consent

Explicit consent is required for remote-capable, automated, microphone,
package, telemetry, and update behavior (SPEC-000). The consent receipt is
stored locally and can be reviewed at any time.

## Diagnostics and Support Bundles

Support bundles are previewable, redacted, reproducible, and
content-addressed (SPEC-026-R07). Before you share one with a maintainer,
preview it — secrets and private content are redacted, and you can confirm
what is included. See [Telemetry](telemetry.md).
