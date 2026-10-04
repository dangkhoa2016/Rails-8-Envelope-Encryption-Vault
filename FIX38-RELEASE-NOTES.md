# Ruby Envelope Vault 0.1.2-FIX38

## Scope

FIX38 makes accepted-release source immutability an enforced release invariant.

## Changes

- Added `script/sealed-source-integrity` with create/verify modes.
- Pre-promotion sealing creates and verifies `SEALED-SOURCE-SHA256SUMS.txt`.
- Post-promotion evidence verifies accepted source bytes before regenerating promoted metadata.
- Release metadata records sealed-source integrity, protected file count, and manifest SHA-256.
- Operator checklist exposes sealed-source integrity.
- Public release history now defaults to the external artifact directory.
- If the release is currently promoted, public-history generation refuses an output path inside the accepted source tree.

## Security boundary

FIX38 does not change envelope encryption, KEK/DEK semantics, MFA, sessions, encrypted-record schema, or secret storage. The new checks protect release provenance and source immutability.
