# Ruby Envelope Vault — Public Showcase Package (FIX26)

This document describes the sanitized portfolio package produced by `script/build-public-showcase`.

## What the package proves

- Rails 8 personal vault UX with purpose-built secret types.
- AES-256-GCM envelope encryption with a fresh DEK for every immutable secret version.
- Separate KEK wrapping and a database that stores ciphertext rather than plaintext vault payloads.
- Reauthentication, TOTP MFA, recovery codes, session controls, throttling, audit history and immutable version history.
- Desktop/mobile UI, synthetic demo fixtures, repeatable screenshots and recovery-oriented release discipline.

## Trust boundary

Ruby Envelope Vault is server-side envelope encryption, not a zero-knowledge password manager. A live authorized Rails host with usable KEK access is trusted and can decrypt vault data.

## Safety

The public package is allowlist-built. It intentionally excludes migration bundles, KEKs, recovery material, environment files, rclone configuration, database dumps and runtime state. Screenshots are generated only from synthetic fixture data.

## Demo banner

When `DEMO_MODE=true`, the application displays a persistent warning that the environment is synthetic-data-only and should not receive real secrets.

## Screenshot evidence

FIX26 captures dashboard, vault, item detail, immutable version history, generator, audit, sessions, security, and mobile views. `MANIFEST.tsv` records pixel dimensions and byte sizes; `SHA256SUMS.txt` records image hashes.
