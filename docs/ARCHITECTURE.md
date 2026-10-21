# Architecture — 1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](ARCHITECTURE.vi.md)
Rails 8 Envelope Encryption Vault is a Rails 8 application backed by PostgreSQL. It stores
encrypted secret versions, wrapped keys, metadata, and audit events.

## Encryption and key custody

Every immutable secret version uses an independently generated fresh random 256-bit DEK.
Authenticated payload encryption uses AES-256-GCM with associated data and integrity checking.
The DEK is wrapped using a configured key-encryption-key provider: local-file or AWS KMS.

The design is not a zero-knowledge design. An authorized, running application with
access to its key provider can decrypt stored secrets.

## Application boundaries

The application implements authentication, multifactor verification,
session management, version history, access checks, and rate limiting.
PostgreSQL holds the encrypted payload and wrapped DEK, not the KEK itself.

Production acceptance is separate from local and synthetic verification.
Live deployment requires explicit operator approval; it is not implied
by passing source-level tests. PROMOTION_REQUIRED=yes remains a
guarded workflow condition, not a claim that promotion occurred.

See [Threat model](THREAT-MODEL.md), [Key management](../KEY-MANAGEMENT.md),
and [Qualification matrix](qualification.md).
