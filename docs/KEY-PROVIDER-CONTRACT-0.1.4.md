# Key Provider Contract — 0.1.4-dev

## Audit finding

The stable 0.1.3 architecture already has a provider boundary through `KeyProviders::Base` and `KeyProviders::Registry`, and encrypted records persist a provider name plus KEK identifier.

However, the key-rotation service instantiated `KeyProviders::LocalFile` directly. That made normal encryption/decryption provider-selectable while rotation remained LocalFile-specific.

## 0.1.4-dev correction

The development line makes two deliberately small changes:

1. `KeyProviders::Base` now includes `verify_key!` in the explicit provider contract.
2. `Vault::RotateKeys` resolves the configured provider through `KeyProviders::Registry.fetch` instead of constructing `LocalFile` directly.

No encrypted-record schema, LocalFile wrapped-key format, AAD structure or KEK custody behavior is changed by this refactor.

## Required provider operations

A production-capable provider must expose:

- `provider_name`
- `active_key_id`
- `verify_key!(key_id = active_key_id)`
- `wrap_key(dek:, context:)`
- `unwrap_key(wrapped_key:, key_id:, context:)`

The provider remains responsible for validating its own key identifiers, wrapped-key format and authentication behavior.

## Compatibility boundary

The existing `local_file` provider remains the only configured production implementation in this milestone so far.

A future external KMS/HSM provider must not be marked production-supported until it has evidence for:

- round-trip DEK wrap/unwrap;
- wrong-key/context failure;
- tamper/authentication failure;
- active-key verification;
- rotation from an old key identifier to the configured active key;
- database-only disclosure boundary;
- backup/restore and disaster-recovery implications;
- safe logging/error behavior;
- provider-specific recovery/custody documentation.

## Non-goals of this refactor

- no AWS/GCP/Azure dependency;
- no automatic KEK export or upload;
- no database migration;
- no change to current stable 0.1.3;
- no claim that a remote KMS provider is already implemented.

The purpose is to remove an unnecessary LocalFile coupling before any external provider is designed.


## Runtime evidence

The 0.1.4-dev provider seam is exercised with a test-only in-memory provider that does not read KEKs from the filesystem and is never registered as a production provider.

Observed evidence:

- in-memory provider round-trip / verify / wrong-key / wrong-context / tamper: 4 runs / 5 assertions / PASS;
- provider-neutral key rotation through `KeyProviders::Registry.fetch`: PASS;
- rotation preserves payload ciphertext while changing wrapped DEK + KEK id;
- reveal after rotation succeeds with the non-LocalFile provider;
- crypto self-test including LocalFile, in-memory and ExternalKms contracts: 26 runs / 49 assertions / PASS.

This demonstrates the abstraction seam without claiming an external KMS implementation exists.
