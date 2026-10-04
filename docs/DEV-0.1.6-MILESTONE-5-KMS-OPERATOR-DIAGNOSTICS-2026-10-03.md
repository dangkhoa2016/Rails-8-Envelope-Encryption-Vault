# DEV-0.1.6 Milestone 5 — KMS Operator Diagnostics & Credential/Outage Hardening

## Goal

Give operators a useful key-provider readiness signal without leaking provider/key/credential detail, and prove that credential-expiry/access-denied/provider-outage failures remain fail-closed and sanitized.

## Implementation

- Added `KeyProviders::Diagnostics` with safe provider/status/category/remote metadata.
- Added `script/key-provider-status`.
- Integrated key-provider readiness into `script/operator-status`.
- Non-ready key provider now makes the combined operator status fail.
- Diagnostics provider names are allowlisted to `local_file`, `aws_kms`, or `unknown`.
- SDK/provider exception text is not exposed.

## Failure-mode coverage

Regression coverage proves:
- expired credential detail maps to generic `unavailable/availability`;
- access-denied ARN/account detail is not exposed;
- wrap failure returns only `KMS wrap unavailable`;
- unwrap failure returns only `KMS unwrap unavailable`;
- unknown provider names are reduced to `unknown`;
- operator scripts contain no AWS credential variables or active KEK ID output.

## Runtime proof

Local-file runtime status on the restored Colab host:

```text
KEY_PROVIDER_NAME=local_file
KEY_PROVIDER_STATUS=ready
KEY_PROVIDER_CATEGORY=none
KEY_PROVIDER_REMOTE=no
OPERATOR_STATUS=PASS
```

No secret values are emitted.

## Verification

Focused diagnostics/security contracts:
- 53 runs / 888 assertions / 0 failures / 0 errors
- RuboCop: 4 files / 0 offenses
- shell syntax: PASS
- runtime key-provider status: PASS
- runtime combined operator status: PASS

Full release verification:
- Rails: 134 runs / 1195 assertions / 0 failures
- system: 21 runs / 192 assertions / 0 failures
- RuboCop: 160 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- crypto: 42 runs / 108 assertions / 0 failures
- security: 5 runs / 12 assertions / 0 failures
- accessibility: 49 runs / 887 assertions / 0 failures
- `RELEASE_VERIFY=PASS version=0.1.6-dev`

Milestone verdict: **PASS / COMPLETE**.
