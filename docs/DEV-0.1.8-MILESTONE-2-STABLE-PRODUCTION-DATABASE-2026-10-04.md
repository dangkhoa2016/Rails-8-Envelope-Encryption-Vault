# Ruby Envelope Vault 0.1.8 — Milestone 2 Stable Production Database Contract

Date: 2026-10-04
Workspace: /content/DEV-0.1.8
Production authority during development: /content/RELEASE-0.1.7

## Result

DEV_0_1_8_MILESTONE_2_STABLE_PRODUCTION_DATABASE=PASS

## Objective

Eliminate the 0.1.7 promotion pattern where production was initially booted
against an acceptance-generated database name such as:

ruby_envelope_vault_dr_accept_<timestamp>_<pid>

and only later renamed manually.

0.1.8 now makes stable production database naming an explicit promotion
contract.

## Deterministic production database name

New helper:

/content/DEV-0.1.8/script/production-database-name

The name is derived from the numeric release version, ignoring DEV/RC suffixes.

Examples:

- 0.1.8-dev -> ruby_envelope_vault_production_v0_1_8
- 0.1.8 -> ruby_envelope_vault_production_v0_1_8
- 0.1.7 -> ruby_envelope_vault_production_v0_1_7

Unsupported version formats fail closed.

The generated identifier is constrained to PostgreSQL's identifier length
contract.

## Live production database contract

New helper:

/content/DEV-0.1.8/script/production-database-contract

It loads only the external production env and validates that DATABASE_URL
points to the deterministic stable database name for the current release.

It does not record DATABASE_URL.

Sanitized evidence records:

- release version
- expected database name
- active database name
- stable_name_contract=true
- database_url_recorded=false
- credential_values_recorded=false
- contains_secret_values=false

## Production startup behavior

script/start-production now uses:

PRODUCTION_DATABASE_CONTRACT_MODE=stable

by default.

In stable mode, startup refuses to continue unless the external DATABASE_URL
uses the correct deterministic database name.

The only supported bypass is explicit:

PRODUCTION_DATABASE_CONTRACT_MODE=isolated

This exists for isolated restore/acceptance harnesses only.

private-dr-restore-acceptance now sets isolated mode explicitly when starting
its temporary acceptance Puma.

## Private DR database-name support

private-dr-restore-acceptance now supports:

--database-name NAME

Without this argument it preserves the historical isolated random name.

With this argument it validates the requested PostgreSQL identifier and
restores directly into that database.

Acceptance evidence now also records the non-secret database_name.

## Keep-DB lifecycle correction

A lifecycle bug was fixed while implementing stable database preparation.

Previously --keep-db could leave a database behind even when acceptance failed
after database creation.

The new contract uses:

- preserve_db=0 initially;
- failure cleanup drops any created database;
- preserve_db=1 only after PRIVATE_DR_ACCEPTANCE=PASS.

Thus a partially restored stable database cannot survive a failed acceptance.

## Stable production DB preparation

New helper:

/content/DEV-0.1.8/script/prepare-production-database

It:

1. computes the stable release database name;
2. refuses to overwrite an existing stable database by default;
3. permits destructive replacement only with explicit --replace;
4. runs private DR restore acceptance directly into the stable name;
5. keeps the database only after full acceptance PASS;
6. runs private DR provenance verification;
7. rolls back the prepared DB if provenance/evidence verification fails;
8. emits sanitized PRODUCTION-DATABASE-PREPARE.json evidence.

The evidence records:

- release version
- database name
- stable-name contract
- restored production counts
- historical decrypt status
- HTTP up/readiness
- accepted private DR artifact
- acceptance/provenance evidence SHA-256
- no DATABASE_URL
- no credential values
- no KMS key IDs
- no plaintext

## Official pre-promotion orchestration

New helper:

/content/DEV-0.1.8/script/release-prepare-promotion

This is the official step intended after prepromote sealing and before
repointing current.

It requires existing prepromote release metadata proving:

- phase=prepromote
- release_verify=pass
- private_dr_restore_acceptance=pass
- private_dr_provenance=pass

It then prepares the stable production database and verifies
PRODUCTION-DATABASE-PREPARE.json.

It deliberately does NOT:

- repoint /content/current
- start production
- modify the sealed release tree

Successful completion emits:

RELEASE_PREPARE_PROMOTION=PASS
PROMOTION_REPOINT_ALLOWED=yes

## Post-promotion enforcement

release-postpromote-evidence now runs production-database-contract against the
live external production env and emits:

PRODUCTION-DATABASE-CONTRACT.json

before final promoted metadata can be written.

Therefore a release cannot produce valid promoted metadata while still using
an acceptance-generated database name.

## Two-phase release metadata

release-metadata now records:

- production_database_prepare
- production_database_live_contract
- production_database_expected_name
- production_database_name
- production_database_stable_name_contract
- production_database_prepare_sha256
- production_database_contract_sha256
- production_database_url_recorded=false
- production_database_credential_values_recorded=false

At prepromote phase:

- preparation/live state may be pending.

At promoted phase:

- production database preparation evidence is mandatory;
- live stable database contract evidence is mandatory;
- both names must match the deterministic release database name.

## Release checklist

release-checklist now displays the stable production database contract,
including:

- expected database
- active database
- preparation status
- live contract status
- evidence SHA-256 values

No URL or credentials are exposed.

## Regression coverage

New test:

/content/DEV-0.1.8/test/production_database_contract_test.rb

Coverage includes:

- deterministic DEV/release naming;
- invalid version rejection;
- stable database URL acceptance;
- acceptance-generated database rejection;
- password/URL non-disclosure;
- stable startup default;
- isolated acceptance mode explicitness;
- keep-db only after acceptance PASS;
- stable preparation workflow;
- promotion orchestration remains non-mutating for current;
- post-promotion live contract requirement.

Targeted regression:

- 65 runs
- 1207 assertions
- 0 failures
- 0 errors
- RuboCop: 4 files / 0 offenses

## Full regression

- Rails: 183 runs / 1723 assertions / 0 failures
- System: 21 runs / 223 assertions / 0 failures
- RuboCop: 169 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- Crypto: 49 runs / 135 assertions / 0 failures
- Security: 5 runs / 12 assertions / 0 failures
- Accessibility: 53 runs / 1116 assertions / 0 failures

Final:

RELEASE_VERIFY=PASS version=0.1.8-dev

## Production safety

No 0.1.8 production database was created during this development milestone.

Production remained pinned to RELEASE-0.1.7.

The stable 0.1.8 production database must only be created later through the
release/private-DR promotion rehearsal using production-authority provenance.

## Recommended next milestone

Improve off-host tool/runtime portability:

- add explicit rclone capability preflight before release/offsite work;
- provision or resolve rclone before expensive promotion gates;
- keep external tool binaries/config outside sealed source integrity;
- preserve the known retry handling for backends that transiently return
  HTTP 501 NotImplemented.
