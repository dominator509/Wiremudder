# WireMudder Privacy Model

## Modes

- Disabled: AI and remote-capable assistance unavailable.
- Local Only: only local providers and local assets; remote egress and downloads blocked.
- Local Preferred: use local providers first and require explicit policy for a remote fallback.
- Remote Redacted: approved remote provider receives a redacted purpose-limited capsule.
- Remote Approved: approved provider receives the specifically previewed content for the current task.

## Data Classes

Public, gameplay, social, private message, voice, diagnostic, profile, routing metadata, secret, signing, and security evidence. Secret and signing data never enter AI or package contexts.

## Consent

Consent is feature, provider, data-class, profile, world, purpose, version, and time scoped; revocable; and auditable. Absence or ambiguity denies egress.
