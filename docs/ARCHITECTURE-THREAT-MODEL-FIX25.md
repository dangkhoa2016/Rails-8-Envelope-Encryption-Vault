# FIX25 Architecture & Threat Model Diagrams

These diagrams summarize the current Ruby Envelope Vault trust and encryption boundaries.

## Application request path

```mermaid
flowchart LR
  B[Browser] -->|TLS / session cookie| R[Rails application]
  R --> A[Authentication + reauthentication + MFA]
  A --> V[Vault services]
  V --> C[Envelope crypto services]
  C --> K[KEK provider]
  C --> P[(PostgreSQL ciphertext)]
  R --> D[(Redis rate/session support)]
```

The live Rails process is trusted because it can request the KEK and decrypt authorized vault payloads.

## Envelope encryption flow

```mermaid
sequenceDiagram
  participant U as User action
  participant V as Vault service
  participant E as Envelope encryptor
  participant K as KEK provider
  participant DB as PostgreSQL

  U->>V: Save secret payload
  V->>E: Serialized plaintext
  E->>E: Generate random DEK
  E->>E: AES-256-GCM encrypt payload
  E->>K: Wrap DEK with active KEK
  K-->>E: Wrapped DEK
  E-->>V: Ciphertext + nonce/tag + wrapped DEK
  V->>DB: Persist encrypted version
```

## Reveal flow

```mermaid
sequenceDiagram
  participant B as Browser
  participant R as Rails
  participant G as Security gates
  participant K as KEK provider
  participant DB as PostgreSQL

  B->>R: Reveal request
  R->>G: Session + recent reauth policy
  G-->>R: Authorized
  R->>DB: Read encrypted version
  R->>K: Unwrap DEK
  K-->>R: DEK
  R->>R: Decrypt in process memory
  R-->>B: Authorized plaintext response
```

## Backup / recovery trust boundary

```mermaid
flowchart TB
  SRC[Released source] --> MB[Migration bundle]
  RC[Recovery material] --> MB
  DB[(Persistent PostgreSQL)] --> BK[Encrypted DB backup]
  MB --> OFF[Off-host release storage]
  BK --> OFF
  OFF --> NEW[New Linux/container host]
  NEW --> SELF[Bootstrap self-heal]
  SELF --> APP[Recovered application]
```

Important boundary: a host that has both the application runtime and the usable KEK is trusted. This project is not a zero-knowledge vault.

## Threat-model summary

Primary mitigations include:

- encrypted-at-rest vault payloads and encrypted tags;
- random per-version DEKs;
- KEK separation;
- immutable encrypted version history;
- recent reauthentication for sensitive operations;
- MFA and recovery codes;
- session expiry/revocation;
- production rate limiting;
- audit metadata rejection/allowlisting;
- source/migration artifact leak checks;
- off-host checksum round trips;
- tested bootstrap/recovery continuity.

These controls reduce risk but do not protect against a fully compromised trusted Rails host while it has access to the KEK.
