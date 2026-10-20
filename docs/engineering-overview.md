# Engineering overview — v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](engineering-overview.vi.md)

## Purpose and non-goals

Ruby Envelope Vault is a self-hosted Rails application that demonstrates how to protect application-managed secrets using authenticated **server-side** envelope encryption. It is designed to make implementation, testing, key custody, and disaster-recovery decisions reviewable in one codebase—not to claim zero-knowledge encryption, formal security certification, high availability, or production hosting approval.

The product handles login credentials, API keys, environment variables, database connections, private notes, server/SSH credentials, and custom records. The Rails application can decrypt for an authorized user; encryption therefore reduces exposure from a **database-only** compromise, but not from a fully compromised live application with KEK access.

## Component responsibilities

| Component | Source location | Responsibility and boundary |
| --- | --- | --- |
| Rails web/API flows | `app/controllers/`, `app/views/` | Authentication, MFA, user-scoped vault actions, settings and audit UI |
| Persistent records | `app/models/`, `db/` | User/item metadata, immutable version rows, ciphertext and wrapped keys |
| Cryptography | `app/services/crypto/` | New DEK and nonce per version, AES-256-GCM, AAD, strict decryption |
| Key providers | `app/services/key_providers/` | Local KEK or AWS KMS wrapping/unwrap operations |
| Vault workflows | `app/services/vault/` | Create, update, reveal, list, restore and DEK rewrap |
| Account security | `app/services/mfa/`, `app/services/security/` | TOTP, recovery factors and related verification |
| Operations | `script/`, `ops/` | Backup, verification, guarded restoration, host preflight and scheduling |
| Verification | `test/`, `.github/workflows/` | Tests, static checks, Ruby compatibility and image build |

### Request and write boundaries

1. An authenticated request reaches the relevant Rails controller.
2. The controller enforces authorization and, for sensitive actions, the appropriate reauthentication workflow.
3. The vault service builds payload and encryption context, using user/item/version identifiers.
4. The envelope encryptor creates a fresh 256-bit DEK and 96-bit GCM nonce, encrypts with AES-256-GCM, and asks the selected provider to wrap the DEK.
5. PostgreSQL stores the resulting encrypted version and permitted metadata. It does **not** store a plaintext KEK.
6. Reveal requires authorized access and a successful unwrap/authentication operation; errors must not expose plaintext or raw key material.

`Vault::RestoreVersion` decrypts an older authorized version, then creates a **new current version** through `Vault::UpdateItem`; historical ciphertext records are not rewritten as part of normal restore.

## Data and trust boundaries

```text
Browser ─ HTTPS ─ Rails/Puma ── authenticated Vault services
                     │                    │
                     │                    ├─ AES-256-GCM (payload)
                     │                    └─ KeyProvider ─ separate KEK custody
                     └─ PostgreSQL ─ ciphertext + wrapped DEK + metadata

Backup path: PostgreSQL → age-encrypted archive → independent storage
Restore path: retrieved archive + separate age identity + required KEKs
              → guarded fresh DB → synthetic canary decrypt
```

The HTTPS, storage and custody boundaries above describe a **correctly configured deployment**. A source checkout or passing CI job does not make those boundaries operational by itself.

## Operational design decisions

- **Per-version keys:** Compromise of a DEK need not reveal every other version; the KEK remains a high-value trust anchor.
- **Authenticated context:** AAD binds encrypted content to its owning user, item and version, preventing a valid payload from being moved to an unrelated context without authentication failure.
- **Metadata is not fully secret:** Item titles, category, timestamps and audit metadata may require additional database privacy controls.
- **Key rotation:** Existing DEKs can be rewrapped under a new KEK while their AES-GCM ciphertext stays unchanged. Keys needed by older backups must remain recoverable.
- **Recoverability:** A valid backup wrapper and checksum alone are not sufficient; the operator must actually restore and decrypt a synthetic canary.
- **Evidence boundaries:** Unit/system tests and source CI provide engineering confidence, not certification of a particular production server.

## Review path for maintainers

Start at [Architecture](ARCHITECTURE.md), then inspect [Threat model](THREAT-MODEL.md), [Key management](KEY-MANAGEMENT.md), [Reproducibility](reproducibility.md), [Qualification](qualification.md), and [Evidence index](evidence-index.md). Before any live use, complete the [Production checklist](PRODUCTION-CHECKLIST.md).

This guide describes the **implementation contract**; refer to the source files for authoritative runtime behavior.
