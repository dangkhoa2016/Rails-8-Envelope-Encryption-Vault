# Ruby Envelope Vault 0.1.7 — Milestone 3: Stable Production Runtime Environment Contract

Date: 2026-10-04
Workspace: `/content/DEV-0.1.7`
Base release: `RELEASE-0.1.6.1`
Development version: `0.1.7-dev`
Fresh host: Google Colab CPU `ef24490855d9`

## Objective

Remove production startup and operator-diagnostic dependence on mutable DEV,
recovery, or source-tree env files.

Production-mode startup must consume an external, mode-restricted environment
file through one shared resolver. Development continues to use
`.env.kaggle`.

## Implementation

Added:

- `script/lib/production-env.sh`
- `script/production-env-path`
- `script/start-production`
- `ops/production.env.example`
- `docs/PRODUCTION-RUNTIME-ENV-0.1.7.md`
- `test/production_env_contract_test.rb`

Updated:

- `script/key-provider-status`
- `script/operator-status`

## Production env resolver

Resolution precedence:

1. explicit `PRODUCTION_ENV_FILE`
2. explicit `OPS_ENV_FILE`
3. readable `/etc/ruby-envelope-vault/ops.env`
4. `${RUNTIME_ROOT}/production.env`
5. notebook runtime default
6. expected persistent-host `/etc/ruby-envelope-vault/ops.env`

Validation requires:

- absolute path
- readable regular file
- path outside the application source tree
- mode 0600 or 0400

The resolver prints paths only and never prints env contents.

## Production startup

`script/start-production`:

- activates tool/runtime paths with `ENV_FILE=/dev/null`
- never falls back to DEV `.env.kaggle`
- loads only the external production env resolver contract
- requires production DB, secret-key, provider, active-key and host settings
- supports independent `PRODUCTION_BIND` and `PRODUCTION_PORT`
- uses a port-specific PID file
- removes only stale PID files
- refuses a duplicate start when the recorded process is still alive

## Operator diagnostics

When production mode or a production env selector is present:

- `script/key-provider-status`
- `script/operator-status`

use the shared external production env resolver.

Development-mode behavior continues to support source-tree `.env.kaggle`.

## Fresh-host source recovery before Milestone 3

The v0.1.7 source backup was restored and verified on a completely new Colab:

- source backup tar SHA256 matched authority: PASS
- source backup ZIP SHA256 matched authority: PASS
- internal source-backup manifest: PASS
- canonical `DEV-0.1.7` restored: PASS
- canonical `RELEASE-0.1.6.1` restored: PASS
- Ruby 3.4.11 bootstrap: PASS
- PostgreSQL 17.11 private cluster: PASS
- Redis 7.0.15 private runtime: PASS
- local-file development KEK: PASS
- database/schema/assets: PASS
- project doctor: PASS
- crypto/security bootstrap checks: PASS

The full Rails test DB required explicit preparation because this host had been
bootstrapped with `RUN_TESTS=0`. The app role remained NOCREATEDB after test
setup.

Fresh-host baseline before Milestone 3:

- Rails: 146 runs / 1353 assertions / 0 failures
- RuboCop: 163 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- security: 4 runs / 26 assertions / 0 failures

## Milestone 3 behavioral acceptance

A temporary, external notebook production-mode env was placed at:

`/content/.ruby-envelope-vault-runtime/production.env`

with mode 0600.

It used only the fresh-host local-file development runtime for acceptance.
No AWS credential file was available on this Colab and none was fabricated.

Results:

- shared resolver selected external runtime env: PASS
- source-tree `.env.kaggle` explicitly supplied as production env: REJECTED
- production-mode DEV server on port 3001: PASS
- DEV `/up`: HTTP 200
- DEV `/ready`: HTTP 200
- DEV Puma cwd: `/content/DEV-0.1.7`
- `key-provider-status`: ready
- `operator-status`: PASS
- `/content/current -> /content/RELEASE-0.1.6.1`
- duplicate production start using the same live PID file: BLOCKED

The temporary production-mode env was removed after acceptance so it cannot be
mistaken for the real AWS-KMS production configuration.

## Regression

Targeted production-env/recovery contract:

- 50 runs / 992 assertions / 0 failures

Final full Rails suite:

- 152 runs / 1387 assertions / 0 failures / 0 errors / 0 skips

Static/security:

- RuboCop: 164 files / 0 offenses
- Brakeman: 0 security warnings
- bundler-audit: no vulnerabilities
- security: 4 runs / 26 assertions / 0 failures

## AWS KMS boundary on this fresh host

This host does not currently contain `ruby-encrypt-env`.

Therefore Milestone 3 does not claim a new live AWS-KMS acceptance on
`ef24490855d9`.

AWS-KMS write/startup guard authority remains the already-proven Milestone 1
and Milestone 2 evidence restored from the source backup. A new live AWS-KMS
acceptance requires credentials supplied out-of-band.

## Result

`DEV_0_1_7_MILESTONE_3_STABLE_PRODUCTION_RUNTIME_ENV=PASS`

Recommended next milestone:

Harden recovery/operator ergonomics for uploaded secret files:

- safe CRLF normalization without editing the uploaded original;
- automatic 0600 enforcement for explicitly selected secret files;
- a secret-safe preflight that reports only presence/mode/format status;
- no credential values, KMS key IDs, or plaintext in evidence.
