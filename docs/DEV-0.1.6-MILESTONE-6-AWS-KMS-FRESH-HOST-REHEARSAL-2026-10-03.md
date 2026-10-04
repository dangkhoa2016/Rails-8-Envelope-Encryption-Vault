# DEV-0.1.6 Milestone 6 — AWS KMS Fresh-Host Recovery Rehearsal

## Status

**READY FOR LIVE AWS EXECUTION**

Synthetic/contract rehearsal: PASS.
Live AWS fresh-host execution: PENDING because this Colab host has no AWS region, KMS key IDs, or credential source configured.

## What was added

- `script/aws-kms-fresh-host-rehearsal`
- machine-readable summary at `tmp/release-artifacts/AWS-KMS-FRESH-HOST-SUMMARY.json`
- recovery contract coverage that preserves the live-evidence boundary and forbids credential values/key IDs in evidence

## Synthetic rehearsal proof

The rehearsal uses the same ExternalKms provider contract with a fake KMS client to prove:

- wrap with an old KMS key;
- decrypt on the recovered host context;
- rewrap under a new KMS key;
- decrypt after rewrap;
- historical decrypt with the original key;
- evidence contains no credential values and no key IDs.

Result:

```text
AWS_KMS_FRESH_HOST_SYNTHETIC=PASS
AWS_KMS_FRESH_HOST_LIVE_STATUS=pending
```

## Live readiness boundary

On this Colab host:

- AWS region: missing
- AWS KMS key id: missing
- two-key IDs: missing
- AWS credential source: missing
- AWS KMS SDK: ready
- `aws-kms-readiness`: `AWS_KMS_LIVE_READY=NO`, exit 2

No live AWS PASS is claimed.

## Verification

Focused recovery contract:
- 41 runs / 850 assertions / 0 failures
- RuboCop: 1 file / 0 offenses
- shell syntax: PASS
- synthetic rehearsal: PASS
- machine-readable evidence: PASS

Full release verification:
- Rails: 135 runs / 1215 assertions / 0 failures
- system: 21 runs / 192 assertions / 0 failures
- RuboCop: 160 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- crypto: 42 runs / 108 assertions / 0 failures
- security: 5 runs / 12 assertions / 0 failures
- accessibility: 50 runs / 907 assertions / 0 failures
- `RELEASE_VERIFY=PASS version=0.1.6-dev`

Milestone verdict: **CONTRACT READY / LIVE AWS EXECUTION PENDING**.

## Live AWS execution — completed

After valid IAM credentials were supplied on the restored Colab host, live execution completed successfully.

Live evidence:

- STS identity validation: PASS
- `aws-kms-readiness`: `AWS_KMS_DESCRIBE_KEY=PASS`, `AWS_KMS_LIVE_READY=YES`
- live single-key smoke: PASS
- key 01 verify: PASS
- key 02 verify: PASS
- old-key wrap/unwrap: PASS
- new-key rewrap/unwrap: PASS
- DEK equality after rewrap: PASS
- historical decrypt using the old key: PASS
- wrong-context rejection: PASS
- Vault-level live rotation: PASS
- ciphertext preservation: PASS
- wrapped-DEK replacement: PASS
- destination KEK id: PASS
- Vault reveal after rotation: PASS
- KeyRegistry state transition: PASS
- rotation audit evidence: PASS
- fresh-host live KMS smoke: PASS

Machine-readable fresh-host summary records:

- `live_aws_ready=yes`
- `live_smoke=pass`
- `historical_decrypt=pass`
- `rewrap=pass`
- `credential_values_recorded=false`
- `key_ids_recorded=false`

### Portability fix discovered during live rehearsal

The three executable live-KMS Ruby scripts originally depended on the caller using Bundler implicitly. On the new Colab host, direct execution could not resolve `aws-sdk-kms`.

Fixed by explicitly loading `bundler/setup` inside:

- `script/aws-kms-live-smoke`
- `script/aws-kms-live-two-key`
- `script/aws-kms-live-vault-rotation`

Recovery-contract coverage now enforces this requirement.

Final verification after live execution and portability fix:

- recovery contract: 42 runs / 856 assertions / 0 failures
- Rails: 136 runs / 1221 assertions / 0 failures
- system: 21 runs / 192 assertions / 0 failures
- RuboCop: 160 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- crypto: 42 runs / 108 assertions / 0 failures
- security: 5 runs / 12 assertions / 0 failures
- accessibility: 51 runs / 913 assertions / 0 failures
- `RELEASE_VERIFY=PASS version=0.1.6-dev`

Final Milestone 6 verdict: **COMPLETE / LIVE AWS PASS**.
