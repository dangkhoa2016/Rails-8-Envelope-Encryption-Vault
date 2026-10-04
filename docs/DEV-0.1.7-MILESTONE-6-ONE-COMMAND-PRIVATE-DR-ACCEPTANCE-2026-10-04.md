# Ruby Envelope Vault 0.1.7 — Milestone 6: One-Command Private DR Restore Acceptance

Date: 2026-10-04
Workspace: `/content/DEV-0.1.7`
Host: Google Colab CPU `ef24490855d9`
Base production authority: `RELEASE-0.1.6.1`

## Objective

Provide one command that can validate a promoted encrypted private-DR artifact
end-to-end on a fresh notebook host without overwriting the development
database and without retaining decrypted recovery material.

## New orchestrator

Added:

`script/private-dr-restore-acceptance`

Required inputs:

- `--archive /absolute/private-dr.tar.gz.age`
- `--outer-key /absolute/outer-recovery.agekey`
- `--aws-secret /absolute/aws.env`

Optional:

- `--evidence /absolute/evidence.json`
- `--keep-db`

Default behavior is cleanup-first: isolated DB and staging material are removed
when the command exits.

## Execution contract

The orchestrator performs:

1. Runtime activation without DEV env auto-loading.
2. Trusted bootstrap env loading for local PostgreSQL/Redis parameters.
3. PostgreSQL/Redis readiness check.
4. Automatic `bootstrap.sh start` self-heal when managed services are down.
5. Outer recovery-key permission validation.
6. AWS secret-file mode validation.
7. Generic secret normalization with `prepare-secret-env`.
8. AWS KMS semantic preflight with `aws-kms-secret-preflight`.
9. Only after secret preflight PASS:
   - outer age decrypt;
   - private-DR internal manifest verification;
   - encrypted database checksum verification;
   - inner age decrypt;
   - pg_restore catalog validation.
10. Creation of an isolated PostgreSQL database owned by the app role.
11. Canonical `script/restore-db` restore through the app-role database URL.
12. Restored catalog count verification.
13. Production env generation only inside protected staging.
14. AWS KMS active-registry/write guard verification.
15. Read-only historical Vault item decrypt check.
16. Production-mode server start on an isolated port.
17. `/up=200` and `/ready=200` verification.
18. Machine-readable non-secret evidence write.
19. Server stop.
20. Isolated DB removal with `dropdb --force`.
21. Full staging/plaintext/normalized-secret cleanup.

## Secret-first fail-closed proof

The current uploaded `/content/ruby-encrypt-env` intentionally remains stale:
its active alias points to historical KEY01 rather than active KEY02.

Running the new orchestrator directly with this file produced:

- semantic preflight exit: 3
- `active-alias-drift`: detected
- outer DR decrypt: NOT reached

Result:

`M6_STALE_ALIAS_BLOCKED_BEFORE_DR_DECRYPT=PASS`

This proves a stale/unsafe AWS configuration cannot cause DR material to be
decrypted before semantic authority is established.

## Happy-path acceptance fixture

For acceptance only, a mode-0600 temporary fixture was generated from the
uploaded credential file with only the active alias changed to KEY02.

The original `ruby-encrypt-env` was not semantically modified.

The fixture passed:

- file hygiene
- required variable checks
- KEY02 active alias match
- KEY01 historical separation
- AWS_SESSION_TOKEN absent

The fixture is temporary and removed during final cleanup.

## End-to-end private DR acceptance

Artifact:

`RUBY-ENVELOPE-VAULT-v0.1.6.1-PRIVATE-DR-PROMOTED-20261003T141227Z.tar.gz.age`

Results:

- AWS secret intake: PASS
- outer encrypted archive decrypt: PASS
- internal manifest: PASS
- encrypted DB checksum: PASS
- inner DB decrypt/catalog: PASS
- canonical app-role restore: PASS

Restored counts:

- users: 1
- vault_items: 1
- vault_item_versions: 1
- key_registries: 2
- audit_events: 92

AWS-backed verification:

- historical decrypt: PASS
- production `/up`: HTTP 200
- production `/ready`: HTTP 200

Final:

`PRIVATE_DR_ACCEPTANCE=PASS`

Machine-readable evidence:

`tmp/release-artifacts/PRIVATE-DR-RESTORE-ACCEPTANCE-M6.json`

Evidence explicitly records:

- `credential_values_recorded = false`
- `key_ids_recorded = false`
- `plaintext_recorded = false`

## Runtime self-heal portability finding

During Milestone 6 a fresh-host runtime issue exposed a real bug in
`prepare-secret-env`.

The helper previously called chmod 0700 on the normalized output's parent
directory even when that parent already existed.

When an acceptance fixture was written directly under `/content`, this
changed:

`/content: 0755 -> 0700`

As a result, the PostgreSQL OS user could no longer traverse to the private
runtime directory.

Fix:

- existing output-parent permissions are never changed;
- a parent is created mode 0700 only when the helper itself creates it;
- a regression test verifies an existing mode-0755 parent remains 0755.

The host `/content` mode was restored to 0755.

## PostgreSQL portability finding

The private PostgreSQL socket lives below the runtime root.

Using `runuser -u postgres` is not portable when an ancestor directory is not
traversable by the postgres OS user.

The Milestone 6 orchestrator now performs private-cluster admin operations by
connecting to the trust-authenticated Unix socket explicitly as database role
`postgres` with `-U postgres`.

The restored database itself is created with owner `vault_user`, and
`script/restore-db` connects using the app-role URL. This avoids the earlier
manual-restore ownership problem.

## Cleanup hardening

An initial successful acceptance left one isolated DB because Puma still had a
connection while ordinary `dropdb` ran during cleanup.

Cleanup was hardened to use:

`dropdb --if-exists --force`

only against the orchestrator-generated prefix:

`ruby_envelope_vault_dr_accept_*`

Final cleanup verification:

- leftover M6 DB count: 0
- leftover M6 staging directory count: 0
- `/content` mode: 0755
- `/content/current -> /content/RELEASE-0.1.6.1`

## Targeted regression

Secret + private-DR contract tests:

- 15 runs / 132 assertions / 0 failures

After parent-permission regression addition:

- 13 runs / 104 assertions / 0 failures
- RuboCop targeted: 2 files / 0 offenses

## Full regression

- Rails: 168 runs / 1548 assertions / 0 failures / 0 errors / 0 skips
- RuboCop: 167 files / 0 offenses
- Brakeman: 0 security warnings
- bundler-audit: no vulnerabilities
- security: 4 runs / 26 assertions / 0 failures

## Result

`DEV_0_1_7_MILESTONE_6_ONE_COMMAND_PRIVATE_DR_ACCEPTANCE=PASS`

## Recommended next milestone

Milestones 1 through 6 have now covered:

- AWS active-key write guard;
- startup/readiness/operator guard;
- stable production env separation;
- secret-file hardening;
- fresh-host secret-safe integration;
- one-command private DR acceptance.

Recommended next step:

Prepare a 0.1.7 release-candidate seal workflow:

- run `release-verify`;
- run the new private-DR acceptance as a release gate;
- create immutable `RELEASE-0.1.7` from DEV only after all gates pass;
- build a new 0.1.7 migration/private-DR bundle;
- verify isolated fresh-host restore;
- promote only after sealed-source integrity and DR evidence PASS.
