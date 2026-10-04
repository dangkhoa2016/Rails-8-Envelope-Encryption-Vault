# DEV-0.1.6 Milestone 4 — KMS Failure-Mode & Rollback Hardening

## Goal

Make key rotation atomic across all affected database records so a provider outage or credential failure cannot leave a partially rotated Vault.

## Change

`Vault::RotateKeys` now runs the mutation phase inside a new Active Record transaction while retaining the existing PostgreSQL advisory lock.

The existing outer error handler remains responsible for a secret-safe `key.rotation_failed` audit event after the transaction rolls back.

## Failure-mode regression

A new regression uses the ExternalKms provider with a fake KMS client that succeeds on the first wrap and fails on the second wrap.

Expected and proven behavior:
- error is normalized to `Crypto::KeyProviderUnavailableError`;
- the first already-updated record is rolled back;
- the second record remains unchanged;
- no destination KeyRegistry activation persists;
- no `key.rotation_completed` audit persists;
- `key.rotation_started` and `key.rotation_failed` remain available for operators.

## Verification

Focused KMS/rotation regression:
- 22 runs / 81 assertions / 0 failures / 0 errors
- focused RuboCop: 2 files / 0 offenses

Full release verification:
- Rails: 127 runs / 1121 assertions / 0 failures
- system: 21 runs / 192 assertions / 0 failures
- RuboCop: 158 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- crypto: 36 runs / 70 assertions / 0 failures
- security: 5 runs / 12 assertions / 0 failures
- accessibility: 48 runs / 851 assertions / 0 failures
- `RELEASE_VERIFY=PASS version=0.1.6-dev`

Milestone verdict: **PASS / COMPLETE**.
