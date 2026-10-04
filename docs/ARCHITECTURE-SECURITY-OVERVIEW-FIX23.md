# Ruby Envelope Vault — Architecture & Security Overview (FIX23)

## Purpose

Ruby Envelope Vault is a Rails 8 self-hosted secrets vault and portfolio/reference implementation built around explicit envelope encryption. It focuses on auditable security boundaries, repeatable recovery, and production-style operational discipline without requiring Docker in Kaggle-style notebook environments.

## Data protection model

Each vault-item version receives a fresh random 256-bit data-encryption key (DEK).

The application:

1. serializes the secret payload;
2. encrypts the payload with AES-256-GCM;
3. authenticates the record with associated data;
4. wraps the DEK with a separate key-encryption key (KEK);
5. stores ciphertext, nonce, authentication tag, wrapped DEK, key identifier and metadata in PostgreSQL.

The KEK is kept outside PostgreSQL and outside the source tree.

This reduces the impact of a database-only disclosure, but it is not a zero-knowledge design. A compromised live application host that can invoke the KEK can potentially decrypt records.

## Main Rails boundaries

- `Vault::CreateItem` / `Vault::UpdateItem`: encrypted version creation.
- `Vault::RevealItem`: explicit decrypt path.
- `Vault::ListItems`: decrypts only application-memory summaries needed for encrypted-title/tag filtering.
- `VaultItemVersion`: immutable encrypted history.
- `AuditEvent`: append-style security history with sensitive-metadata validation.
- `Session`: server-side expiry, activity tracking, revocation and reauthentication state.
- MFA services: encrypted TOTP secret storage, replay protection and one-time recovery codes.

## Authentication and sensitive operations

The product includes password authentication, TOTP MFA, one-time recovery codes, recent reauthentication gates, server-side session idle/absolute expiry, session revocation, password-change session rotation, and Rack::Attack throttling for sensitive endpoints.

## Product privacy behavior

Plaintext is intentionally transient:

- encrypted payloads remain ciphertext in PostgreSQL;
- reveal is explicit;
- sensitive browser fields are marked for Turbo/cache scrubbing;
- clipboard feedback is transient;
- generated secrets are produced locally with Web Crypto;
- tags remain inside the encrypted payload rather than being duplicated as plaintext searchable columns.

## Friendly observability without weakening raw evidence

FIX23 separates operator/developer identifiers from product copy:

- Audit UI shows friendly event titles and descriptions.
- Raw action identifiers remain present for filtering and debugging.
- Session UI derives a coarse browser/OS/device label from the existing User-Agent.
- Raw User-Agent remains available in a collapsed technical-detail section.
- No additional device fingerprinting is introduced.

## Runtime and recovery architecture

Notebook/container runtime state that must survive source-directory churn lives under:

`/kaggle/working/.ruby-envelope-vault-runtime`

This includes persistent PostgreSQL data, Redis runtime data/config, Ruby/mise state, Bundler state, Selenium cache and KEK material.

The bootstrap process can self-heal runtime-only losses such as missing PostgreSQL/Redis binaries, missing PostgreSQL runtime-only directories, missing Chrome shared libraries, lost executable bits in persistent Selenium or mise binaries, and stale generated web assets.

## Asset integrity

Generated `public/assets` are not release-source artifacts.

At startup/release preparation the application removes stale generated assets, builds Tailwind, precompiles Propshaft assets, and verifies the fingerprinted Tailwind CSS contains required responsive utilities.

## Release discipline

A release is not considered authoritative until all applicable checks pass:

- Ruby/Rails tests;
- browser system tests;
- RuboCop;
- Brakeman;
- bundler-audit;
- crypto self-tests;
- security self-tests;
- responsive-asset verification;
- source leak checks;
- migration-bundle internal/portability checks;
- isolated restore;
- health-gated promotion;
- project doctor;
- persistent artifact checksums;
- off-host round-trip checksum verification.

## Deployment model

For public portfolio/demo use, use fake data only.

For a personal vault, use a separate host/database/KEK, disable public signup, enable MFA, and maintain tested encrypted backups.

A public demo and a personal vault should not share production secrets or key material.
