# Ruby Envelope Vault 0.1.8.1-dev — Fresh-host portability hotfix

Date: 2026-10-05
Base: promoted `0.1.8` (`8d9795665e25d2c0d7b18d7eba81397d2338b1b2`)
Branch: `dev-0.1.8.1`

## Scope

This hotfix captures defects found during a real restore of the promoted 0.1.8 POSTPROMOTE FULL PRIVATE bundle onto a fresh Colab host. The promoted `RC-0.1.8` remains immutable.

## Defect 1 — `bootstrap.sh start` on a fresh host

Observed behavior:

- PostgreSQL, Redis and Ruby self-healed successfully;
- `start` then executed `build_web_assets`;
- the fresh runtime had no installed gem bundle;
- Rails failed with `Bundler::GemNotFound`.

Fix:

- `bootstrap.sh start` now runs `bundle check` before asset build;
- it calls the existing `install_bundle` path only when the bundle is missing;
- warm/restarted hosts do not reinstall a valid bundle.

## Defect 2 — private DR runtime env propagation

Observed behavior during `release-prepare-promotion`:

```text
PRODUCTION_DATABASE_REPLACE=PASS
PRIVATE_DR_ACCEPTANCE=FAIL reason=runtime-env-unavailable
```

Root cause:

- `prepare-production-database` activates tools with `ENV_FILE=/dev/null`;
- `private-dr-restore-acceptance` chooses `PRIVATE_DR_RUNTIME_ENV_FILE`, then inherited `ENV_FILE`, then `.env.kaggle`;
- the caller did not explicitly pass the trusted runtime env, so `/dev/null` won.

Fix:

```text
PRIVATE_DR_RUNTIME_ENV_FILE="$runtime_env"
```

is now explicitly supplied by `prepare-production-database`.

## Defect 3 — production env is partly host-local

The copied production env from the old host could not be used unchanged on the new host:

- the PostgreSQL role/password belonged to the old runtime;
- `SECRET_KEY_BASE` and active KEK fields could be placeholders in a portability bundle;
- production startup therefore failed even though the restored DB itself was valid.

New helper:

```text
script/rebuild-production-env
```

It rebuilds only host-local/security-critical production fields from trusted new-host authority:

- stable production DB name from `VERSION`;
- PostgreSQL role/password/host/port from the new runtime `DATABASE_URL`;
- `SECRET_KEY_BASE` from the new runtime env;
- `VAULT_KEY_PROVIDER=aws_kms`;
- active key from `AWS_KMS_KEY_ID`.

AWS access credentials remain outside `production.env`.

Optional `--base-production-env` preserves non-host-local production policy settings such as hosts, URL, SSL, signup, MFA and reauthentication while discarding old DB credentials and placeholder secret/key values.

## POSTPROMOTE full-private orchestrator

New command:

```text
script/restore-postpromote-full-private
```

Default recovery sequence:

1. verify encrypted archive sidecar when available;
2. decrypt with the outer recovery identity;
3. verify internal SHA-256 manifest;
4. require promoted release metadata;
5. run Git fsck on restored RC and DEV repositories;
6. validate the PostgreSQL dump catalog;
7. restore source and release evidence;
8. restore private authority with restrictive permissions;
9. run fresh-host `bootstrap.sh setup`;
10. rebuild production env using current-host runtime/KMS authority;
11. restore the stable production database through the app-role URL;
12. validate the production database contract.

Live mutation remains explicit:

- `--inspect-only`: verification only, no host mutation;
- `--repoint-current`: explicitly repoint `current`;
- `--start-production`: requires `--repoint-current` and waits for `/up=200` and `/ready=200`.

## Validation

Completed on the same host while promoted 0.1.8 remained live:

- targeted production/private-DR regression suite: **24 tests / 229 assertions / 0 failures**;
- full Rails unit suite: **203 runs / 1,973 assertions / 0 failures**;
- recovery contract suite after orchestrator addition: **45 runs / 1,088 assertions / 0 failures**;
- `script/project-doctor`: PostgreSQL, Redis, crypto and security self-tests PASS;
- `script/portability-check`: PASS;
- `restore-postpromote-full-private --inspect-only` against the real promoted 0.1.8 POSTPROMOTE bundle: PASS;
- inspect-only left `/content/current` unchanged and `RC-0.1.8` clean.

Full `script/release-verify`: **PASS** for `0.1.8.1-dev` (204 Rails tests / 1,995 assertions; 21 system tests / 223 assertions; RuboCop clean; Brakeman 0 warnings; bundler-audit no vulnerabilities; crypto/security/accessibility gates PASS).

## Release boundary

This work is development-only until fresh-host acceptance and the normal release seal/promotion process are repeated. Do not mutate the promoted 0.1.8 source tree to apply these fixes.
