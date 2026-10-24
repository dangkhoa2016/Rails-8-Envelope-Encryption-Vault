# Changelog

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](CHANGELOG.vi.md)
## 1.0.0 — First Community Source Release

The first source release of Ruby Envelope Vault provides a Rails 8 application, reproducible verification workflows, and bilingual English/Vietnamese documentation.

### Review-ready improvements
- Reactive Audit filters and stateful Vault search that keep decrypted titles and tags out of URLs.
- In-place Favorite toggling on Vault item details, retaining URL and keyboard focus.
- Shared accessible success/error toast notifications, including Turbo Stream updates.
- Dependency maintenance: `crass` 1.0.8 addresses GHSA-pq4g-8rxf-4g29.
- One reproducible Kaggle/Colab notebook that pins the reviewed application commit and its exact Git tree.

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
