# Security Policy

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](SECURITY.vi.md)
## Supported source

Version 1.0.0 is the initial public source release. Passing isolated tests does not establish production deployment security.

## Reporting a vulnerability

Report security issues privately to Đăng Khoa at i.am@dangkhoa.dev. Do not post access tokens, encryption keys, recovery codes, database URLs, session cookies, real vault content, or vulnerability proofs involving real data in public issues.

Provide a minimal reproducible example using synthetic credentials and data.

## Security model

- Vault versions use authenticated AES-256-GCM encryption with independently generated data-encryption keys.
- Key-encryption-key custody is separated from the encrypted records stored in PostgreSQL.
- MFA, rate limiting, reauthentication, access controls and audit trails are additional controls.
- This is server-side encryption, **not zero knowledge**: a compromised authorized live application can access decryption capability.

## Production boundary

A successful isolated test is not permission to store real secrets. A production installation requires real-host TLS, key custody, recovery, offsite backup verification, monitoring and the acceptance gates listed in [PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md). Review the [qualification matrix](qualification.md) to distinguish source test evidence from host-specific acceptance.
