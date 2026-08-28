# Security

Security is built on the principle of default deny. The full threat model
is in [WIREMUDDER_SECURITY.md](../../../WIREMUDDER_SECURITY.md) and the
security design docs.

## Secrets

Secrets (API keys, tokens, passwords) are protected. No script, package,
Soul document, or AI action can read your secrets without explicit
permission (WM-SPEC-008-R04). Logs and evidence are redacted so secrets
never appear in diagnostics (WM-FEAT-0230).

## Command Safety

Commands that could be dangerous are reviewed before being sent. The
command-safety gate requires your approval for risky commands and records
the decision (WM-FEAT-0176).

## Permissions

Permissions cover filesystem, network, microphone, AI egress, secrets,
routing, updater, telemetry, UI, command send, memory, renderer, and audio
access. Default is deny. Approval is per-package and per-request; an
update cannot expand permissions silently (WM-SPEC-008-R05).

## Injection Defense

Input is treated as hostile. Scripts and packages cannot inject commands
into the manual gameplay path. The injection guard is tested against
hostile-input corpora.

## No Egress Without Consent

Nothing on your machine sends data anywhere unless you configured a
provider and granted a permission. There is no hidden telemetry endpoint
(SPEC-026-R08).
