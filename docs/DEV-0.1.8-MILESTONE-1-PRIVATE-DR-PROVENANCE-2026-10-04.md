# Ruby Envelope Vault 0.1.8 — Milestone 1 Production DR Provenance Gate

Date: 2026-10-04
Workspace: /content/DEV-0.1.8
Base production authority: /content/RELEASE-0.1.7

## Objective

Convert the 0.1.7 lesson "a technically valid private DR can be built from the
wrong DEV database" into a durable fail-closed release contract.

A private DR must now prove both:

1. it restores/decrypts/boots successfully; and
2. the database snapshot is explicitly a production-authority snapshot with
   provenance tied to the exact encrypted archive.

## Added

script/private-dr-provenance-preflight

test/private_dr_provenance_preflight_test.rb

## Provenance contract

A release private DR provenance document must have:

- schema_version = 1
- status = pass
- snapshot_role = production-authority
- target_release_version equal to VERSION
- artifact basename equal to the archive under test
- artifact_sha256 equal to the exact archive bytes
- production_authority_confirmed = true
- source_equals_runtime_database = false
- source_type = production-database or promoted-private-dr
- source_release_version present
- database counts present and above release minimums
- credential/key-id/plaintext flags all false

Current release minimums are:

- users >= 1
- vault_items >= 1
- vault_item_versions >= 1
- key_registries >= 2
- audit_events >= 1

These minimums preserve the production historical-decrypt canary and the
two-key AWS KMS registry authority expected by this project.

## Inherited promoted snapshot contract

When source_type is promoted-private-dr and source_release_version differs from
the target release, provenance must explicitly prove:

migration_set_identical = true

This captures the exact path used for the final 0.1.7 production DR, where the
promoted 0.1.6.1 encrypted production snapshot was inherited only after the
0.1.6.1 and 0.1.7 migration sets were proven identical.

## Acceptance binding

The provenance preflight also consumes PRIVATE-DR-RESTORE-ACCEPTANCE evidence.

It requires:

- acceptance artifact basename matches the same archive;
- outer decrypt PASS;
- database restore PASS;
- historical decrypt PASS;
- HTTP up=200;
- HTTP ready=200;
- acceptance counts exactly equal provenance counts;
- no credential values, KMS key IDs or plaintext recorded.

A provenance JSON cannot therefore claim production counts different from what
the restore gate actually observed.

## Release workflow integration

release-seal-prepromote now requires:

- RELEASE_PRIVATE_DR_ARCHIVE
- RELEASE_PRIVATE_DR_OUTER_KEY
- RELEASE_PRIVATE_DR_PROVENANCE_FILE
- RELEASE_AWS_SECRET_FILE

The order is:

1. private-dr-restore-acceptance
2. private-dr-provenance-preflight
3. sanitized PRIVATE-DR-PROVENANCE.json evidence
4. remaining release build/seal flow

Missing provenance fails closed.

## Release metadata

release-metadata now validates PRIVATE-DR-PROVENANCE.json and records only
non-secret fields:

- private_dr_provenance = pass
- private_dr_snapshot_role
- private_dr_source_type
- private_dr_source_release_version
- private_dr_target_release_version
- private_dr_production_authority_confirmed
- private_dr_source_equals_runtime_database
- private_dr_provenance_sha256

The release checklist renders the same authority state.

## Regression acceptance

Targeted provenance/recovery contracts:

- 50 runs
- 1047 assertions
- 0 failures
- 0 errors
- RuboCop: 4 files / 0 offenses

Fail-closed cases covered:

- current runtime database claimed as production source: BLOCKED
- target release mismatch: BLOCKED
- production counts below minimums: BLOCKED
- provenance/acceptance count mismatch: BLOCKED
- inherited promoted DR without migration identity proof: BLOCKED

## Full regression after Milestone 1

- Rails: 174 runs / 1613 assertions / 0 failures
- System: 21 runs / 223 assertions / 0 failures
- RuboCop: 168 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- Crypto: 49 runs / 135 assertions / 0 failures
- Security: 5 runs / 12 assertions / 0 failures
- Accessibility: 53 runs / 1092 assertions / 0 failures

Final:

RELEASE_VERIFY=PASS version=0.1.8-dev

## Result

DEV_0_1_8_MILESTONE_1_PRIVATE_DR_PROVENANCE=PASS

## Recommended next milestone

Make stable production database naming a first-class promotion contract so
promotion never temporarily inherits acceptance-generated DB names.
