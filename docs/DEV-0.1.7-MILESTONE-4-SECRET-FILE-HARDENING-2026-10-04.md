# Ruby Envelope Vault 0.1.7 — Milestone 4: Uploaded Secret-File Hardening

Date: 2026-10-04
Workspace: `/content/DEV-0.1.7`

## Objective

Make notebook/remote-host secret-file intake safe and repeatable without
printing secret values.

The implementation focuses on the exact fresh-host problems observed during
0.1.6.1/0.1.7 recovery:

- notebook uploads may arrive mode 0644;
- Windows-created env files may contain CRLF;
- secret files may be malformed or incomplete;
- AWS KMS alias drift must be reported without printing key IDs.

## Generic secret env preparation

Added:

`script/prepare-secret-env`

Capabilities:

- requires an absolute input path;
- verifies regular/readable file;
- reports input mode only;
- reports CRLF presence only;
- reports NUL-byte presence only;
- validates required variable names from `REQUIRED_SECRET_VARS`;
- never prints variable values;
- `--fix-input-mode` explicitly changes the selected input to mode 0600;
- `--check-only` performs no normalized-copy write;
- otherwise creates a normalized LF-only copy;
- normalized output is always mode 0600;
- original content is not semantically changed.

## AWS KMS semantic preflight

Added:

`script/aws-kms-secret-preflight`

This script does not source/execute the env file. It parses assignment lines as
data and reports only safe metadata.

It requires non-empty:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- AWS_KMS_KEY_ID
- AWS_KMS_KEY01_ID
- AWS_KMS_KEY02_ID

It reports only:

- presence
- file mode/restriction state
- CRLF/NUL state
- required variable presence
- whether active alias matches KEY02
- whether active alias differs from KEY01
- whether AWS_SESSION_TOKEN is present
- final PASS/FAIL reason

It never prints credential or KMS key values.

Exit semantics:

- 0: safe mode + required variables + active alias authority PASS
- 2: file/format/required-variable/mode failure
- 3: active alias drift

## Live file acceptance

The uploaded `/content/ruby-encrypt-env` was processed using the new generic
helper:

- mode: 0600
- mode restricted: yes
- CRLF: no
- NUL: no
- all six required AWS/KMS variable names: present
- normalized copy mode: 0600
- generic secret env status: PASS

AWS-specific semantic preflight correctly returned:

- active alias matches KEY02: no
- active alias differs from KEY01: no
- AWS_SESSION_TOKEN: absent
- status: FAIL reason=active-alias-drift
- exit code: 3

No values were printed.

This is intentional. File hygiene and semantic key authority are separate
concerns; the helper must not silently rewrite which KMS key is active.

## Regression

Targeted generic + AWS secret helper tests:

- 7 runs / 73 assertions / 0 failures

Generic + production env tests:

- 10 runs / 76 assertions / 0 failures

Final project regression after all Milestone 4 additions:

- Rails: 159 runs / 1460 assertions / 0 failures / 0 errors / 0 skips
- RuboCop: 166 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- security: 4 runs / 26 assertions / 0 failures

## Security properties

- no credential values in stdout/stderr/evidence;
- no KMS key IDs in stdout/stderr/evidence;
- original upload is never semantically corrected automatically;
- normalized copies are mode 0600;
- CRLF normalization happens only in the protected copy;
- NUL-containing files fail closed;
- alias drift fails closed before production use.

## Result

`DEV_0_1_7_MILESTONE_4_SECRET_FILE_HARDENING=PASS`

Recommended next milestone:

Integrate `prepare-secret-env` and `aws-kms-secret-preflight` into the
fresh-host restore/bootstrap workflow so recovery automatically performs the
same secret-safe intake checks before any AWS-backed Rails process starts.
