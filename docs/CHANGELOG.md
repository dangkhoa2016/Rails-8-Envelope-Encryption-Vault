# Changelog

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](CHANGELOG.vi.md)
## 1.0.0 — Initial Source Release

This is the first published source release of Rails 8 Envelope Encryption Vault.

### Features
- Rails 8 application and PostgreSQL-backed encrypted vault entries
- AES-256-GCM authenticated envelope encryption, immutable versions and audit records
- Local-file and AWS KMS key-encryption-key provider integrations
- MFA, session controls, rate limiting, secret exports and version restoration

### Engineering
- Automated security, request and regression tests, and Docker/CI workflows
- Backup, recovery and controlled deployment acceptance tooling
- MIT License, architecture and operator documentation

A source release does not demonstrate production deployment acceptance.
Follow the [production checklist](PRODUCTION-CHECKLIST.md) and [security policy](SECURITY.md) before deploying with real secrets.
