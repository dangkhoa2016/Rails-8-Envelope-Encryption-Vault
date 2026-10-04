# Ruby Envelope Vault 0.1.7 — Milestone 2: AWS KMS Startup and Operator Readiness Guard

Date: 2026-10-03
Workspace: `/content/DEV-0.1.7`
Base release: `RELEASE-0.1.6.1`
Development version: `0.1.7-dev`

## Objective

Detect AWS KMS active-key configuration drift before serving write traffic, not only at the first encryption attempt.

Milestone 1 already enforced a write-time fail-closed guard. Milestone 2 extends the same authority check into:

- production boot
- HTTP readiness
- operator diagnostics
- AWS KMS readiness tooling
- operational readiness gate

## Shared authority

The authoritative rule remains:

1. exactly one `KeyRegistry` row must have:
   - provider = `aws_kms`
   - status = `active`
2. configured `VAULT_ACTIVE_KEK_ID` must equal that row's `kek_id`

The implementation reuses `KeyProviders::AwsKmsActiveKeyGuard.verify!`; no duplicate key-selection logic was introduced.

## Production startup enforcement

`config/initializers/production_environment_check.rb` now registers an `after_initialize` production check.

When:

- `RAILS_ENV=production`
- `VAULT_KEY_PROVIDER=aws_kms`
- production boot checks are not explicitly skipped

the boot process invokes:

`KeyProviders::AwsKmsActiveKeyGuard.verify!(VAULT_ACTIVE_KEK_ID)`

A mismatch raises a generic production registry-check failure and prevents Rails from completing boot.

No KMS key ID is included in the error.

## Runtime readiness enforcement

`HealthController#ready` now verifies:

- database connectivity
- key-provider availability
- provider write authorization

A registry/config mismatch returns HTTP 503 and an empty response body.

`/up` remains the lightweight process-health endpoint.

## Operator diagnostics

`KeyProviders::Diagnostics.call` now invokes provider write authorization.

Therefore:

- matching AWS KMS registry/config => `ready / none`
- active-key drift => `misconfigured / configuration`
- provider outage => `unavailable / availability`

Only safe classification fields are exposed.

`script/key-provider-status` and `script/operator-status` inherit this behavior automatically.

`script/ops-check` now explicitly invokes `provider.assert_write_allowed!` in its production Rails probe.

## AWS KMS readiness command

`script/aws-kms-readiness` retains its remote KMS DescribeKey check and now additionally boots Rails production context and requires the registry active-key guard to pass.

Safe output includes:

- `AWS_KMS_DESCRIBE_KEY=PASS`
- `AWS_KMS_REGISTRY_ACTIVE_MATCH=PASS`
- `AWS_KMS_LIVE_READY=YES`

On registry/config drift it emits only:

`AWS_KMS_REGISTRY_ACTIVE_MATCH=FAIL`

and exits non-zero.

No key value is printed.

## Regression tests

Targeted Milestone 2 contract set:

- 58 runs
- 1022 assertions
- 0 failures
- 0 errors
- 0 skips

The targeted set covers:

- HTTP readiness
- provider diagnostics
- active-key guard
- Registry guard injection
- recovery/startup contract

## Live restored-database acceptance

Using the restored 0.1.6.1 production database on the fresh Colab:

Correct active configuration:

- production boot after_initialize guard: PASS

Deliberately selecting the known decrypt-only key:

- production boot: BLOCKED
- Rails runner body did not execute: PASS
- failure evidence contained no KMS key ID: PASS

Correct configuration restored afterward:

- `script/aws-kms-readiness`: PASS
- AWS KMS remote key availability: PASS
- registry active match: PASS
- `script/key-provider-status`: ready
- `script/ops-check`: PASS

## Parallel DEV HTTP acceptance

A separate production-mode DEV process was started on port 3001 without changing the live production symlink.

Results:

- DEV `/up`: HTTP 200
- DEV `/ready`: HTTP 200
- DEV Puma cwd: `/content/DEV-0.1.7`

Production remained simultaneously:

- port 3000 health: HTTP 200
- `/content/current -> /content/RELEASE-0.1.6.1`

## Full validation

Full Rails suite:

- 146 runs
- 1353 assertions
- 0 failures
- 0 errors
- 0 skips

Static/security:

- RuboCop: 163 files / 0 offenses
- Brakeman: 0 security warnings
- bundler-audit: no vulnerabilities
- security suite: 4 runs / 26 assertions / 0 failures

## Incidental fresh-host findings

Two rehearsal-only issues were identified while starting the parallel DEV server:

1. The copied DEV tree inherited a stale `tmp/pids/server-3000.pid` from the sealed source copy.
   - Only the DEV-tree stale PID file was removed.
   - Production PID files were not touched.

2. The runtime env file contains `PORT=3000`, which overrode an earlier helper assignment.
   - The DEV helper was corrected to export `PORT=3001` after sourcing env files.

Neither issue affected production or the AWS KMS guard implementation.

## Production isolation

Throughout Milestone 2:

- production remained `/content/RELEASE-0.1.6.1`
- production health remained HTTP 200
- production was never repointed to `DEV-0.1.7`

## Milestone result

`DEV_0_1_7_MILESTONE_2_AWS_KMS_STARTUP_OPERATOR_GUARD=PASS`

Recommended next milestone:

Consolidate production runtime configuration so live startup helpers no longer depend on development/recovery-specific env paths, while preserving the sealed release and current DR authority.
