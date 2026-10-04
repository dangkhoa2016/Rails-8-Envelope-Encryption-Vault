# FIX24 Release Notes — UX Refinement & Accessibility

FIX24 is forked from the fully accepted FIX23 baseline.

## Improvements

- Audit log safe-context chips driven by an explicit metadata allowlist.
- Optional truncated request/item technical references without dumping arbitrary metadata.
- Session screen distinguishes Current, Active, Revoked and Expired states.
- Current browser is additionally labeled “This device”.
- Generator quick presets: Balanced 24, Strong 32 and Compatible 20.
- Copy generated/current secret directly from the secret input.
- Search-space estimate based on configured alphabet and length, explicitly labeled as an estimate rather than a security guarantee.
- Global focus-visible treatment and reduced-motion safeguards.
- Registration validation summary uses alert semantics.
- Full responsive/accessibility asset verification remains part of release gates.

## Security invariants

FIX24 does not change the envelope-encryption format, KEK separation, MFA design, reauthentication gates, session expiry/revocation model, encrypted tags, immutable version history, or rate limits.

Audit metadata is never rendered generically. Only action-specific allowlisted keys are eligible for display.
