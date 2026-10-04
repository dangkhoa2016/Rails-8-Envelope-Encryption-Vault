# Ruby Envelope Vault 0.1.7 — Milestone 5: Secret-Safe Fresh-Host Recovery Integration

Date: 2026-10-04
Workspace: `/content/DEV-0.1.7`
Host: Google Colab CPU `ef24490855d9`

## Objective

Integrate the Milestone 4 secret-file hardening tools into fresh-host recovery
and AWS live-rehearsal entrypoints so uploaded credential files are validated
before any AWS-backed readiness or live smoke action can proceed.

## Hardened generic env normalization

`script/prepare-secret-env` was upgraded from byte-level CRLF normalization
to data-only env parsing.

It now:

- accepts comments and simple assignment lines only;
- accepts optional `export NAME=value` syntax;
- rejects shell statements and unsupported syntax;
- never executes input content;
- parses values with shell lexical rules;
- rewrites normalized output as shell-safe literal exports;
- preserves command-substitution-looking text as literal data;
- creates normalized output mode 0600;
- retains explicit `--fix-input-mode` semantics;
- never prints values.

Regression proves that a line such as a standalone `touch ...` command is
rejected rather than copied, and a value that looks like `$(...)` remains
literal after sourcing the normalized file.

## restore-new-host integration

`script/restore-new-host` now inspects the restored source env safely to
identify `VAULT_KEY_PROVIDER`.

When recovered provider is `aws_kms`:

1. `NEW_HOST_AWS_SECRET_FILE` is mandatory.
2. The path must be absolute.
3. Input mode must already be 0600/0400 unless
   `NEW_HOST_FIX_SECRET_MODE=1` was explicitly requested.
4. `script/prepare-secret-env` creates a protected normalized copy.
5. `script/aws-kms-secret-preflight` validates:
   - required AWS/KMS variables;
   - active alias authority;
   - secret-file mode;
   - NUL/format safety.
6. Only after both helpers PASS does recovery emit:
   `AWS_SECRET_INTAKE=PASS`.
7. The normalized credential copy is deleted immediately after preflight.

No credential value or KMS key ID is written to recovery output.

The new-host machine-readable summary records only safe fields:

- `recovered_key_provider`
- `aws_secret_intake`

## AWS fresh-host rehearsal integration

`script/aws-kms-fresh-host-rehearsal` now accepts:

- `AWS_KMS_SECRET_FILE=/absolute/path`
- optional `AWS_KMS_FIX_SECRET_MODE=1`

When live AWS acceptance is required:

- missing secret file fails before readiness;
- unsafe mode fails before normalization unless explicit fix was requested;
- normalized copy is placed only in a mode-0700 temporary directory;
- generic env hardening runs first;
- AWS semantic preflight runs second;
- normalized env is sourced only after both checks PASS;
- only then may `aws-kms-readiness` or live smoke run.

The rehearsal summary now records:

`secret_intake = pass | skip`

and still records:

- `credential_values_recorded = false`
- `key_ids_recorded = false`

## Live stale-upload behavioral proof

Using the current uploaded `/content/ruby-encrypt-env`:

### Existing mode-0600 stale alias

`AWS_KMS_SECRET_FILE=/content/ruby-encrypt-env`
with live required returned exit 3.

Observed:

- semantic result: `active-alias-drift`
- no `AWS_KMS_DESCRIBE_KEY=PASS`
- no live registry smoke
- therefore AWS live work did not begin

Result:

`STALE_ALIAS_BLOCKED_BEFORE_AWS_LIVE=PASS`

### Unsafe mode without opt-in repair

A temporary copy was set to mode 0644.

Without fix opt-in:

- result: `unsafe-input-mode`
- exit code: 2
- original test copy remained 0644

Result:

`UNSAFE_UPLOAD_WITHOUT_OPTIN=BLOCKED`

### Explicit mode repair

The same temporary copy was retried with:

`AWS_KMS_FIX_SECRET_MODE=1`

Results:

- input mode changed to 0600;
- generic secret intake proceeded;
- AWS semantic guard then stopped on stale alias;
- no AWS live readiness was reached;
- exit code: 3

Result:

`EXPLICIT_MODE_FIX_THEN_ALIAS_GUARD=PASS`

## Targeted regression

Fresh-host/secret integration contract:

- 53 runs
- 1066 assertions
- 0 failures
- 0 errors
- 0 skips

Hardened helper targeted tests:

- 9 runs
- 84 assertions
- 0 failures

## Final full regression

- Rails: 161 runs / 1495 assertions / 0 failures / 0 errors / 0 skips
- RuboCop: 166 files / 0 offenses
- Brakeman: 0 security warnings
- bundler-audit: no vulnerabilities
- security: 4 runs / 26 assertions / 0 failures

## Security boundary

Milestone 5 deliberately does not auto-correct KMS semantic authority.

The currently uploaded `ruby-encrypt-env` remains stale:

- file hygiene: acceptable after mode hardening;
- active alias authority: FAIL;
- expected semantic preflight exit: 3.

The operator must explicitly repair the intended active alias outside this
workflow. The recovery tooling only detects and blocks the mismatch.

## Result

`DEV_0_1_7_MILESTONE_5_SECRET_SAFE_FRESH_HOST_INTEGRATION=PASS`

Recommended next milestone:

Create a first-class, one-command private DR restore orchestrator for 0.1.7 that
combines:

- encrypted DR artifact verification/decrypt;
- isolated PostgreSQL restore through the app role;
- secret-safe AWS intake;
- active-key semantic preflight;
- historical decrypt verification;
- production-mode `/ready` acceptance;
- automatic cleanup of decrypted/staged material;
- machine-readable non-secret evidence.
