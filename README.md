# Ruby Envelope Vault

A Ruby on Rails 8 self-hosted secrets vault demonstrating server-side envelope encryption, immutable version history, multifactor authentication, and evidence-driven recovery.

**Current source candidate:** 0.1.8.3 (release candidate; not promoted to a live production deployment).

## Features

- AES-256-GCM authenticated encryption with a fresh data-encryption key (DEK) for each immutable secret version.
- Local-file and AWS KMS key-encryption-key (KEK) provider boundaries.
- Secure notes, login credentials, API keys, environment variables and generic secrets.
- Version restore, audit records, secret export, TOTP MFA and recovery codes.
- Reauthentication, session expiry and revocation, rate limiting and production security checks.
- Rails 8, PostgreSQL 17, Hotwire and Tailwind CSS.

## Security boundary

This is **not** a zero-knowledge password manager. An authorized live server with access to its KEK provider can decrypt secrets. PostgreSQL contains encrypted payloads, wrapped keys and metadata, not the KEK itself. Production deployment requires careful key custody, access controls and backup recovery tests.

## Candidate status

The 0.1.8.3 application has passed isolated HTTP E2E workflows, 31 security/request/service tests (124 assertions), a further synthetic cookie integration test (8 assertions), production-mode boot and HTTP checks, and Rails production login-page/asset delivery through an internal HTTPS proxy. These results do **not** imply live production promotion.

The sealed candidate-specific offhost roundtrip, full guarded promotion rehearsal and strict acceptance on durable production hosting remain incomplete. See [Publication status](docs/PUBLICATION-STATUS.md).

## Getting started

Review [security policy](SECURITY.md), [threat model](THREAT-MODEL.md), and [key management](KEY-MANAGEMENT.md) before running the application. Ruby 3.4.x and PostgreSQL 17 are used for the verified candidate. Consult [setup guidance](KAGGLE-SETUP.md) for a notebook/demo environment and [production checklist](PRODUCTION-CHECKLIST.md) for real-host requirements.

The files `ops/production.env.example` and `config/deploy.yml` are templates containing placeholders; they are not deployable as-is. Use a separate development/test database and synthetic data for acceptance.

## Documentation

| Area | Reference |
| --- | --- |
| Candidate readiness | [Publication status](docs/PUBLICATION-STATUS.md), [Publication checklist](docs/PUBLICATION-CHECKLIST.md) |
| Security | [Security policy](SECURITY.md), [Threat model](THREAT-MODEL.md) |
| Operations | [Production checklist](PRODUCTION-CHECKLIST.md), [Backup and restore](BACKUP-RESTORE.md) |
| Key custody | [Key management](KEY-MANAGEMENT.md) |
| Release history | [Changelog](CHANGELOG.md) |
| Historical engineering records | [Documentation index](docs/README.md) |

## License

Licensed under the [MIT License](LICENSE). Copyright (c) 2026 Đăng Khoa <i.am@dangkhoa.dev>.

Use synthetic data when reporting issues and privately disclose security vulnerabilities to the maintainer.
