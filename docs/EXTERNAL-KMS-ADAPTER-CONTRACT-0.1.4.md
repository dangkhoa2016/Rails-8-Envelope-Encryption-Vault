# External KMS Adapter Contract — 0.1.4-dev

## Status

This is a vendor-neutral adapter skeleton and test contract only.

It is **not** registered as a production provider. The first concrete development client is now AWS KMS; production Registry activation remains closed.

## Purpose

The adapter proves that Ruby Envelope Vault can keep KEK custody outside the application host while preserving the existing envelope-encryption record model.

The application still generates a random 32-byte DEK locally. The external KMS client only wraps and unwraps that DEK.

## Required client interface

A vendor adapter supplied to `KeyProviders::ExternalKms` must implement:

- `key_available?(key_id:)`
- `encrypt(key_id:, plaintext:, encryption_context:)`
- `decrypt(key_id:, ciphertext:, encryption_context:)`

The client returns an opaque encrypted blob. Ruby Envelope Vault does not interpret vendor-specific ciphertext.

## Capabilities

The skeleton advertises:

- remote KEK custody: yes;
- opaque wrapped-DEK blob: yes;
- encryption context binding: yes;
- local KEK export: no.

The adapter does not expose or persist KEK bytes.

## Stored wrapped-key envelope

The application-level wrapper stores only:

- wrapper version;
- provider name;
- key identifier;
- base64-encoded opaque KMS ciphertext.

No credential, endpoint token or KEK material belongs in the wrapped-key blob.

## Encryption context

The adapter binds each operation to:

- user id;
- vault item id;
- vault item version id;
- fixed purpose string `ruby-envelope-vault-dek-wrap-v1`.

A vendor adapter must preserve equivalent authenticated context semantics.

## Error contract

Configuration failures map to `Crypto::KeyProviderConfigurationError`.

Remote/key availability failures map to `Crypto::UnknownKeyError` or `Crypto::KeyProviderUnavailableError`.

Malformed or mismatched wrapped blobs map to `Crypto::KeyUnwrapError`.

External client exception messages must not be propagated to user-facing/application-level errors because they may contain endpoint, account, credential or provider details.

## Recovery and custody requirements

Before any real external KMS adapter can be production-supported, operators must document and prove:

1. who controls the cloud/KMS account;
2. key deletion and disable protections;
3. region/project/subscription recovery procedure;
4. credential recovery independent from the application database;
5. key alias/version pinning behavior;
6. restore behavior when the newest active key is unavailable;
7. ability to decrypt historical wrapped DEKs after rotation;
8. outage behavior and operator diagnostics;
9. backup/DR restoration on a fresh host;
10. rollback behavior after failed key rotation.

## Production-registration gate

`KeyProviders::Registry` intentionally still rejects `external_kms`.

A concrete vendor provider must not be added to the registry until:

- vendor SDK/configuration is explicit;
- credentials are supplied outside source/database;
- contract tests pass;
- rotation integration passes;
- failure/logging redaction is proven;
- recovery/DR is proven;
- operator documentation is complete.

## Current evidence

Provider-neutral evidence still uses a fake KMS client; AWS-specific client tests use an injected SDK stub and do not require cloud credentials:

- external KMS contract: 7 runs / 20 assertions / PASS;
- external KMS rotation through the registry seam: PASS;
- production registry remains closed to `external_kms`;
- stable 0.1.3 remains unchanged.

This evidence proves the adapter boundary, not a cloud-provider implementation.
