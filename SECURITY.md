# Security Policy

## Supported source

The current reviewed source candidate is **0.1.8.3 RC**. It has completed isolated application and security checks, but has **not** been promoted to a live production deployment. Earlier versions documented in the changelog are historical; do not infer current support from their archived release notes.

## Reporting a vulnerability

Report security issues privately to the repository maintainer. Do not post access tokens, encryption keys, recovery codes, database URLs, session cookies, real vault content, or vulnerability proofs involving real data in public issues.

Provide a minimal reproducible example using synthetic credentials and data.

## Security model

- Vault versions use authenticated AES-256-GCM encryption with independently generated data-encryption keys.
- Key-encryption-key custody is separated from the encrypted records stored in PostgreSQL.
- MFA, rate limiting, reauthentication, access controls and audit trails are additional controls.
- This is server-side encryption, **not zero knowledge**: a compromised authorized live application can access decryption capability.

## Production boundary

A successful isolated test is not permission to store real secrets. A production installation requires real-host TLS, key custody, recovery, offsite backup verification, monitoring and the acceptance gates listed in [PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md). See [Publication status](docs/PUBLICATION-STATUS.md) for outstanding RC gates.
