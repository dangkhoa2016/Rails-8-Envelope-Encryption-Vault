# DEV-0.1.6 Milestone 3 — AWS KMS Authority Audit

## Finding

Stable `0.1.4-RELEASE-NOTES.md` is the relevant release authority and records that AWS KMS support was accepted before 0.1.4 promotion.

Current code agrees with that authority:
- `KeyProviders::Registry` explicitly supports `aws_kms`;
- configuration is fail-closed when region or active key id is missing;
- `AwsKmsClient` uses AWS KMS Encrypt/Decrypt with encryption context;
- provider-neutral and live-acceptance scripts preserve historical-key and ciphertext invariants.

The stale state was documentation inherited from early 0.1.4 development, not a missing Registry implementation.

## Current focused regression

- Registry + AWS KMS client + ExternalKms + rotation: **21 runs / 71 assertions / 0 failures / 0 errors**.
- These counts match the accepted focused KMS/rotation numbers recorded in stable 0.1.4 release notes.

## Documentation reconciliation

Updated:
- `docs/AWS-KMS-IMPLEMENTATION-0.1.4.md`
- `docs/ROADMAP-0.1.4.md`
- `docs/ROADMAP-0.1.6.md`
- `CHANGELOG.md`

## Boundary and future hardening

This milestone does not change AWS KMS runtime behavior or claim new live-cloud evidence.

Future hardening remains useful for:
- credential-expiry behavior;
- provider outage behavior;
- fresh-host cloud-specific recovery;
- failed-rotation rollback rehearsal;
- expanded operator diagnostics/redaction review.

These are tracked as hardening work, not as prerequisites for an activation that already occurred in accepted stable 0.1.4.

Milestone verdict: **authority reconciled; no KMS code change required**.
