# Ruby Envelope Vault 0.1.2-FIX37

## Scope

FIX37 surfaces the already-proven deep public showcase package integrity result as structured, non-secret release evidence.

## Changes

- `script/public-showcase-validate` can emit external `PUBLIC-PACKAGE-INTEGRITY.json`.
- The JSON records release version, status, link count, screenshot count, manifest rows, root-file count, and deep integrity statuses.
- The evidence file remains outside the public showcase archive, avoiding checksum self-reference.
- `script/release-metadata` requires passing integrity evidence and publishes structured integrity fields.
- `script/release-checklist` surfaces the same status and metrics for operators.
- Pre-promotion sealing copies the integrity evidence into the canonical artifact directory.
- Release-history generation recognizes FIX37.

## Security / trust boundary

No cryptographic semantics, KEK/DEK behavior, MFA logic, session behavior, or encrypted-record schema changed in FIX37. The integrity JSON contains no credentials, environment values, recovery material, database URLs, Redis URLs, or service tokens.
