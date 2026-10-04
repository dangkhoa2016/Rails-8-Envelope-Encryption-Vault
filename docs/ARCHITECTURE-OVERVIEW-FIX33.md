# Architecture Overview — FIX33

This document is a public, source-controlled architecture map for Ruby Envelope Vault. It summarizes already-established architecture and threat-model boundaries; it does not introduce new cryptographic claims.

## System context

```mermaid
flowchart LR
    U[Authorized user / browser]
    A[Rails 8 application]
    P[(PostgreSQL)]
    K[LocalFile KEK provider]
    R[Redis runtime support]
    B[Backup / restore tooling]
    O[Off-host artifact storage]

    U -->|HTTPS / authenticated flows| A
    A -->|ciphertext + metadata| P
    A -->|wrap / unwrap DEKs| K
    A -->|runtime support| R
    P -->|database backup| B
    K -->|recovery material managed separately| B
    B -->|verified release / recovery artifacts| O
```

## Envelope-encryption path

```mermaid
sequenceDiagram
    participant User
    participant Rails
    participant Crypto as EnvelopeEncryption
    participant KEK as KEK Provider
    participant DB as PostgreSQL

    User->>Rails: Create or update secret
    Rails->>Crypto: Encrypt plaintext + authenticated context
    Crypto->>Crypto: Generate fresh random 256-bit DEK
    Crypto->>Crypto: AES-256-GCM encrypt payload
    Crypto->>KEK: Wrap DEK
    KEK-->>Crypto: Wrapped DEK + key id
    Crypto-->>Rails: Ciphertext, nonce, tag, wrapped DEK, metadata
    Rails->>DB: Persist encrypted version
```

## Read / reveal path

```mermaid
sequenceDiagram
    participant User
    participant Rails
    participant DB as PostgreSQL
    participant KEK as KEK Provider
    participant Crypto as EnvelopeEncryption

    User->>Rails: Authorized reveal/export request
    Rails->>Rails: Authentication + authorization + reauthentication checks
    Rails->>DB: Read encrypted version
    Rails->>Crypto: Decrypt encrypted record
    Crypto->>KEK: Unwrap DEK
    KEK-->>Crypto: DEK
    Crypto-->>Rails: Plaintext in authorized application flow
    Rails-->>User: Controlled response
```

## Trust boundaries

- PostgreSQL is expected to contain ciphertext and encryption metadata, not plaintext vault payloads or the KEK.
- The KEK is kept outside PostgreSQL and Git.
- A live authorized Rails host with KEK access is trusted and can decrypt data. This is therefore not a zero-knowledge design.
- Public demo deployments use synthetic data only and must not reuse personal KEKs or real credentials.
- Backup/recovery material and source/public showcase artifacts have different sensitivity and are packaged separately.

## Release-evidence path

```mermaid
flowchart TD
    F[Fork authoritative release]
    V[release-verify]
    S[release-seal-prepromote]
    I[Isolated restore]
    H[Explicit promotion + health check]
    E[Post-promotion evidence]
    C[Operator checklist]
    RH[Release history]
    O[Off-host round-trip SHA verification]

    F --> V --> S --> I
    I -->|PROMOTION_REQUIRED=yes| H
    H --> E --> C --> RH --> O
```

The promotion boundary is deliberate: the pre-promotion seal never changes the live `current` symlink or restarts Puma.
