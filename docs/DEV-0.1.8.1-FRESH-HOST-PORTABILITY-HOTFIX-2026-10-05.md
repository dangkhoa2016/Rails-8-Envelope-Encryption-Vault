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

Full `script/release-verify`: **PASS** for `0.1.8.1-dev` on the final fresh-host code (205 Rails tests / 2,014 assertions; 21 system tests / 223 assertions; 54 accessibility tests / 1,170 assertions; RuboCop clean; Brakeman 0 warnings; bundler-audit no vulnerabilities; crypto/security gates PASS).

## Release boundary

This work is development-only until fresh-host acceptance and the normal release seal/promotion process are repeated. Do not mutate the promoted 0.1.8 source tree to apply these fixes.

## Cross-version restore helper correction

A follow-up audit found that the first orchestrator revision attempted to call `rebuild-production-env` from the restored `RC-0.1.8` tree. That sealed release correctly does not contain the new 0.1.8.1 hotfix helper.

The corrected design keeps the helper in the hotfix tree and adds:

```text
--release-root /absolute/restored-release
```

`rebuild-production-env` now uses the restored release root only for stable database naming and the production database contract. This allows a `0.1.8.1-dev` recovery tool to restore a sealed `0.1.8` bundle without altering the restored source or accidentally deriving the `0.1.8.1` database name.

Validated on the live host with a temporary output file:

```text
REBUILD_PRODUCTION_ENV=PASS
release root: RC-0.1.8
database_name=ruby_envelope_vault_production_v0_1_8
provider=aws_kms
placeholder values: absent
AWS access credentials embedded: no
```

A repository regression test also uses a stub older release root to guarantee that the helper does not derive the hotfix version's DB name.

### Why a full local restore was not run on the promoted host

The default full recovery path intentionally restores the deterministic stable production DB name. Running it on the same host that is actively serving promoted 0.1.8 would drop/recreate the live stable database and therefore would not be an isolated rehearsal.

The safe same-host boundary is therefore:

- real POSTPROMOTE ciphertext `--inspect-only`;
- internal manifest/Git/DB-catalog verification;
- cross-version host-local production-env rebuild into a temporary file;
- regression/release gates.

The first full end-to-end restore with DB recreation, optional repoint, production start and postpromote evidence must run on a fresh Colab host.


## Fresh-host end-to-end acceptance — 2026-10-05

A completely new Google Colab CPU host was used with only the downloaded artifacts:

- promoted 0.1.8 POSTPROMOTE FULL PRIVATE ciphertext;
- its outer recovery identity and checksum;
- the 0.1.8.1-dev source checkpoint.

### Additional defects found and fixed

#### `pg_restore` catalog check ran before fresh-host provisioning

The first `--inspect-only` invocation correctly verified the outer archive, internal manifest and promoted metadata, but the host did not yet have PostgreSQL tooling. The earlier orchestrator incorrectly collapsed this condition into `invalid-database-dump`.

The orchestrator now:

- reports `reason=pg_restore-missing` explicitly for inspect-only precondition failure;
- performs the mandatory database catalog check after bootstrap in full restore mode;
- emits `POSTPROMOTE_DATABASE_CATALOG=PASS` only after a real `pg_restore -l` succeeds.

After provisioning PostgreSQL 17.11, inspect-only passed against the real ciphertext and real production dump.

#### Full-private DB dump has manifest integrity but no adjacent `.sha256`

The POSTPROMOTE FULL PRIVATE bundle protects the database dump through the bundle-wide internal SHA-256 manifest. `script/restore-db`, however, also requires a sibling `.sha256` sidecar.

After the internal manifest and DB catalog have both passed, the orchestrator now derives a temporary sibling sidecar from the already-verified extracted dump before calling canonical `restore-db`. The sidecar exists only in temporary extraction state and does not modify the archive or sealed 0.1.8 source.

### Full one-command restore result

The final fresh-host invocation used:

```text
--replace-source --repoint-current --start-production
```

and completed with:

```text
POSTPROMOTE_ARCHIVE_SHA256=PASS
POSTPROMOTE_INTERNAL_MANIFEST=PASS
POSTPROMOTE_BUNDLE_METADATA=PASS version=0.1.8
POSTPROMOTE_SOURCE_VERIFY=PASS
POSTPROMOTE_SOURCE_RESTORE=PASS
POSTPROMOTE_PRIVATE_AUTHORITY_RESTORE=PASS
POSTPROMOTE_BOOTSTRAP=PASS
POSTPROMOTE_DATABASE_CATALOG=PASS
POSTPROMOTE_PRODUCTION_ENV_REBUILD=PASS
POSTPROMOTE_DATABASE_SIDECAR=PASS
POSTPROMOTE_DATABASE_RESTORE=PASS database_name=ruby_envelope_vault_production_v0_1_8
POSTPROMOTE_REPOINT=PASS current=/content/RC-0.1.8
POSTPROMOTE_PRODUCTION_START=PASS up=200 ready=200
POSTPROMOTE_RESTORE=PASS version=0.1.8
```

The restored stable production DB contained the expected authority counts:

```text
users=1
vault_items=1
vault_item_versions=1
key_registries=2
audit_events=92
```

### AWS KMS / historical recovery validation

On the new host:

- AWS secret intake and active-alias checks: PASS;
- live AWS KMS verify/wrap/unwrap: PASS;
- wrong-context rejection: PASS;
- error redaction: PASS;
- fresh-host synthetic historical decrypt/rewrap: PASS;
- official private-DR restore acceptance: PASS;
- actual historical decrypt from restored private DR: PASS;
- private-DR `/up` and `/ready`: 200/200.

### Drime read-after-write finding

Reusing the existing root path `drime:ruby-envelope-vault/RELEASE-METADATA.json` produced a checksum mismatch because Drime returned a previous object version after overwrite; the remote metadata and its remote sidecar were internally consistent with the same old SHA.

A unique acceptance prefix was created and strict capability/write probing passed:

```text
drime:ruby-envelope-vault/fresh-host-acceptance-20261005T030247Z
```

`release-postpromote-evidence` then passed against that prefix, and local metadata, remote metadata and remote sidecar all matched SHA-256:

```text
ff06b6000a1d6f4c543947eabb8feed511039e4396b07b1aff0137e39a9f35f4
```

This is treated as a backend overwrite/read-after-write behavior, not a release metadata integrity failure. Fresh acceptance and future immutable evidence uploads should use unique remote prefixes rather than overwriting a previously used evidence object name.

### Final fresh-host state

```text
/content/current -> /content/RC-0.1.8
VERSION=0.1.8
UP=200
READY=200
RC_DIRTY=0
phase=promoted
promotion_performed=true
offhost_roundtrip=pass
```

`RELEASE_CHECKLIST=PASS` and `RELEASE_HISTORY=PASS` were regenerated on the fresh host.
