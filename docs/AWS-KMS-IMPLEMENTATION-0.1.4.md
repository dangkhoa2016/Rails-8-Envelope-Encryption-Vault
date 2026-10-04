# AWS KMS Implementation — 0.1.4-dev

## Status

AWS KMS began as the first concrete external-KMS client target during 0.1.4 development and was subsequently accepted into stable 0.1.4.

`KeyProviders::Registry` now explicitly supports `aws_kms` with fail-closed configuration validation. Stable 0.1.4 release authority records live two-key KMS acceptance, service-level rotation, historical decrypt verification, and full regression/static/security gates before promotion.

## Architectural fit

The existing ExternalKms contract maps directly to AWS KMS symmetric Encrypt/Decrypt with EncryptionContext.

The application still generates each 32-byte DEK locally. AWS KMS only wraps and unwraps that DEK; KEK bytes never enter Ruby Envelope Vault.

## Implementation files

- app/services/key_providers/aws_kms_client.rb
- test/services/key_providers/aws_kms_client_test.rb
- script/aws-kms-readiness
- script/aws-kms-live-smoke
- docs/AWS-KMS-RUNTIME-IAM-POLICY-0.1.4.json.template

## Required live configuration

Provide outside source control:

- AWS_REGION or AWS_DEFAULT_REGION
- AWS_KMS_KEY_ID
- an approved short-lived AWS credential source

Do not write access keys, session tokens, credentials, or key material into source, database, artifacts, or logs.

## Runtime IAM

The runtime principal should normally receive only:

- kms:DescribeKey
- kms:Encrypt
- kms:Decrypt

Scope these actions to the exact KMS key ARN.

Key creation, alias/policy administration, disablement, and deletion are provisioning privileges and are deliberately excluded from the runtime policy.

## Live evidence

Run script/aws-kms-readiness first. Only when it reports AWS_KMS_LIVE_READY=YES, run bundle exec ruby script/aws-kms-live-smoke.

Expected evidence markers:

- AWS_KMS_VERIFY_KEY=PASS
- AWS_KMS_WRAP=PASS
- AWS_KMS_UNWRAP=PASS
- AWS_KMS_WRONG_CONTEXT=PASS
- AWS_KMS_ERROR_REDACTION=PASS
- AWS_KMS_LIVE_SMOKE=PASS

## Encryption-context safety

AWS KMS encryption context is authenticated but is not secret and may appear in audit logs.

Never place passwords, tokens, vault plaintext, DEKs, or other secret values in the context.

Ruby Envelope Vault uses identifiers plus the fixed purpose ruby-envelope-vault-dek-wrap-v1.

## Accepted production evidence and future hardening

Stable 0.1.4 release authority records the following as accepted before promotion:

1. live KMS round-trip evidence;
2. two-key rotation evidence;
3. historical decrypt after rotation;
4. service-level Vault rotation with ciphertext preservation;
5. production Registry activation for `aws_kms` with explicit fail-closed configuration.

Additional credential-expiry/outage drills, fresh-host cloud-specific recovery, failed-rotation rollback exercises, and expanded operator diagnostics remain worthwhile future hardening. They are not described here as uncompleted activation gates because AWS KMS support was already accepted and promoted in 0.1.4.

## Provider-neutral recovery evidence

The ExternalKms rotation integration test now additionally proves:

- the pre-rotation wrapped DEK remains decryptable with the historical old key;
- payload ciphertext remains unchanged during rotation;
- a freshly reconstructed ExternalKms provider using the same external key service can reveal the rotated item;
- production Registry support is explicitly available for `aws_kms` and remains fail-closed on missing/invalid configuration.

This is provider-neutral/fake-client recovery evidence. It does not replace live AWS KMS or fresh-host cloud recovery evidence.
