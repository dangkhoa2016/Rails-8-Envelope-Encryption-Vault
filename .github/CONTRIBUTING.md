# Contributing — 1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](CONTRIBUTING.vi.md)
Thanks for reviewing Rails 8 Envelope Encryption Vault. Open an issue to discuss substantial changes before preparing a pull request.

## Engineering rules

1. Preserve the AES-256-GCM envelope model, independent DEK generation and KEK custody boundaries.
2. Do not commit credentials, actual vault data, backups, KEKs, KMS tokens or private acceptance evidence.
3. Keep the first source release version 1.0.0 unless release management explicitly creates a new version.
4. Update both the English and Vietnamese versions of any changed documentation.
5. Include reproducible test commands, expected outputs and clear failure cases.
6. Prefer focused, reviewable changes; keep unrelated refactors out of security fixes.

## Before submitting

Run the applicable Rails tests, static analysis and the bilingual documentation validator. For sensitive changes, document the affected trust boundary and an isolated synthetic reproduction.

Use the [pull request template](PULL_REQUEST_TEMPLATE.md) and follow the [code of conduct](CODE_OF_CONDUCT.md).
