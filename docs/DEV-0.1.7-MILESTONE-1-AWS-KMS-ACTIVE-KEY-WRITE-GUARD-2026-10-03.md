# Ruby Envelope Vault 0.1.7 — Milestone 1: AWS KMS Active-Key Write Guard

Date: 2026-10-03
Workspace: `/content/DEV-0.1.7`
Base release: `RELEASE-0.1.6.1`
Development version: `0.1.7-dev`

## Objective

Prevent any new AWS-KMS-backed encryption from using a configured key that does not match the single `KeyRegistry` row marked `active`.

This hardens the configuration drift discovered during the exact fresh-host DR rehearsal, where the operator alias initially pointed at a decrypt-only key while the database registry correctly marked a different key as active.

Historical decrypt must remain available through decrypt-only keys.

## Design

The write guard is enforced only on encryption paths.

`Crypto::EnvelopeEncryptor.encrypt` now invokes:

`key_provider.assert_write_allowed!`

The base provider implementation is a no-op so local-file and test providers preserve existing behavior.

For production `aws_kms`, `KeyProviders::Registry.fetch` injects `AwsKmsActiveKeyGuard.verify!` into the `ExternalKms` provider.

The guard requires:

1. exactly one `KeyRegistry` row with:
   - provider = `aws_kms`
   - status = `active`
2. the active row's `kek_id` to equal the configured `VAULT_ACTIVE_KEK_ID`.

If either condition is false, encryption fails closed with a generic `Crypto::KeyProviderConfigurationError`.

KMS key IDs are not included in the error message.

Decrypt/unwrap paths do not invoke the write guard. Historical decrypt-only keys remain usable.

## Write-path coverage

Current application encryption entry points all flow through `EnvelopeEncryptor.encrypt`:

- Vault item creation
- Vault item update/version creation
- MFA secret creation/setup

Therefore all current new-ciphertext paths receive the guard.

Key rotation rewrap uses provider `wrap_key` directly and retains its existing rotation-specific safety contract. It is not accidentally blocked by the general new-write guard.

## Files changed

- `app/services/key_providers/aws_kms_active_key_guard.rb` — new fail-closed registry validator
- `app/services/key_providers/base.rb` — default `assert_write_allowed!` hook
- `app/services/key_providers/external_kms.rb` — optional injected write guard
- `app/services/key_providers/registry.rb` — inject guard for production `aws_kms`
- `app/services/crypto/envelope_encryptor.rb` — enforce provider write authorization before generating/wrapping a new DEK
- `test/services/key_providers/aws_kms_active_key_guard_test.rb`
- `test/services/key_providers/registry_write_guard_test.rb`

## Regression evidence

Targeted key-provider/crypto regression:

- 25 runs / 61 assertions / 0 failures / 0 errors

Dedicated guard + registry-injection regression:

- 6 runs / 18 assertions / 0 failures / 0 errors

Full Rails suite after final test additions:

- 143 runs / 1319 assertions / 0 failures / 0 errors / 0 skips

Static/security checks:

- RuboCop: 163 files / 0 offenses
- Brakeman: 0 security warnings
- bundler-audit: no vulnerabilities
- crypto focused test: 7 runs / 9 assertions / 0 failures
- security suite: 4 runs / 26 assertions / 0 failures

## Restored production-registry acceptance

Using the restored 0.1.6.1 database on the fresh Colab:

- configured active key matches active KeyRegistry: PASS
- matching configuration write guard: PASS
- deliberately selecting decrypt-only key: BLOCKED
- error message leaked no KMS key ID: PASS
- historical AWS-KMS decrypt after guard introduction: PASS

No production record was created or modified by this acceptance probe.

## Production isolation

The running production release remained:

`/content/current -> /content/RELEASE-0.1.6.1`

Final checks after development changes:

- production health: HTTP 200
- Puma cwd: `/content/RELEASE-0.1.6.1`

No sealed release file was modified.

## Milestone result

`DEV_0_1_7_MILESTONE_1_AWS_KMS_ACTIVE_KEY_WRITE_GUARD=PASS`

The next useful step is to harden operator/startup diagnostics so the same registry/config mismatch is detected before serving write traffic, not only at the moment a new encryption is attempted.
