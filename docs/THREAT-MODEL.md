# Threat Model — 1.0.0
## Assets
> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](THREAT-MODEL.vi.md)

- Vault plaintext and `.env` values;
- per-version DEKs;
- local/cloud KEKs;
- login passwords and authenticated sessions;
- TOTP seed and recovery codes;
- encrypted database and backup artifacts.

## Trust boundaries

```text
Browser -> HTTPS/reverse proxy -> Rails/Puma -> PostgreSQL
                                  |
                                  +-> KeyProvider / mounted KEK
```

Offline backup storage and offline KEK recovery storage are separate trust boundaries.

## Protected scenarios

The design materially reduces damage from:

- database-only compromise;
- stolen `pg_dump` / PostgreSQL snapshot without KEK access;
- accidental SQL inspection;
- ciphertext/tag/nonce/AAD tampering;
- cross-record ciphertext swapping;
- long-lived stolen session after idle/absolute expiration;
- brute-force concentration through application-level throttles;
- account takeover using password alone when MFA is enabled;
- plaintext TOTP-seed exposure through the database;
- leaked recovery-code database rows (bcrypt hashes only).

## Out of scope / residual risk

This is not zero-knowledge encryption. Full compromise of a live Rails host that can invoke the active KeyProvider can potentially decrypt data. The design also cannot fully protect against:

- compromised client/browser/OS;
- keylogger or malicious browser extension;
- malicious code in the Rails process;
- simultaneous compromise of DB + usable KEK/provider authorization;
- malicious administrator with authorized live-process access.

## Cryptographic invariants

- AES-256-GCM payload encryption;
- fresh 32-byte DEK per Vault version;
- fresh 12-byte nonce per data encryption;
- 16-byte authentication tag;
- AAD binds user/item/version;
- DEK persisted only in wrapped form;
- KEK remains outside PostgreSQL/Git;
- KEK rotation rewraps DEKs rather than re-encrypting data ciphertext;
- TOTP seeds use the same envelope-encryption primitive;
- recovery codes use one-way bcrypt hashes.

## Operational invariants

- production signup disabled unless explicitly running fake-data demo mode;
- MFA required for personal production by default;
- reveal/export requires recent reauthentication by default;
- production HTTPS and Host Authorization enabled;
- backup is not accepted until restore+decrypt passes.
