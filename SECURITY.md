# Security Policy

## Scope

Ruby Envelope Vault is a security-sensitive self-hosted application. Do not include real credentials, API keys, KEKs, recovery codes, database URLs, private keys, session cookies, or decrypted payloads in public bug reports.

## Supported version

Security fixes target the newest tagged release. v0.1.2 is the Kaggle/bootstrap hardening milestone and must still pass `PRODUCTION-CHECKLIST.md` in the actual deployment environment before real-secret use.

## Reporting

Report a suspected vulnerability privately to the repository owner/maintainer. Include reproduction steps using synthetic data only.

## Cryptographic assumptions

- payloads use AES-256-GCM with fresh random DEKs and nonces;
- DEKs are wrapped by a separate KEK provider;
- KEKs are not stored in PostgreSQL or Git;
- TOTP seeds are envelope-encrypted;
- recovery codes are bcrypt-hashed;
- application login passwords are bcrypt-hashed and are never reversibly encrypted.

## Important limitation

This is server-side envelope encryption, not a zero-knowledge vault. Complete compromise of an authorized live application host may expose decryptable data because that host can use the active key provider.
