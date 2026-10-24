# Changelog

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](CHANGELOG.vi.md)
## 1.0.0 — First Community Source Release

The first source release of Rails 8 Envelope Encryption Vault provides a Rails 8 application, reproducible verification workflows, and bilingual English/Vietnamese documentation.

### Highlights
- Security Activity Center: account-scoped activity cards, 7/30/90-day filters, conservative outcomes, dated timelines and allowlisted event details.
- Session audits show bounded browser/User-Agent, resolved IP, HTTP method/route; Vault audit entries link existing owned items.
- Reactive Audit filters and stateful Vault search that keep decrypted titles and tags out of URLs.
- Vault searches all authorized encrypted title/tag candidates without truncation; unfiltered pages decrypt only the selected page.
- Vault lists Active items by default; Archive retains ciphertext and versions while Archived and All states remain explicit choices.
- In-place Favorite toggling on Vault item details, retaining URL and keyboard focus.
- Shared accessible success/error toast notifications, including Turbo Stream updates.
- Dependency maintenance: `crass` 1.0.8 addresses GHSA-pq4g-8rxf-4g29.
- One reproducible Kaggle/Colab notebook that checks out the reviewed annotated release source and prints its Git commit/tree for verification.

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
