# Ruby Envelope Vault 0.1.7 — Fresh-Host AWS KMS Live Acceptance Addendum

Date: 2026-10-04
Host: Google Colab CPU `ef24490855d9`
Workspace: `/content/DEV-0.1.7`
Base release: `RELEASE-0.1.6.1`

## Purpose

Complete a new live AWS-KMS acceptance on the fresh Colab used for Milestone 3,
after AWS credentials were supplied out-of-band in `/content/ruby-encrypt-env`.

No credential values, KMS key IDs, or decrypted Vault plaintext were written to
this evidence.

## Uploaded credential file preflight

Initial upload:

- present: yes
- initial mode: 0644
- CRLF: no
- NUL bytes: no
- required AWS/KMS variable names: present
- AWS_SESSION_TOKEN: absent

The file mode was corrected to 0600 before use.

Semantic preflight found the uploaded aliases were stale:

- `AWS_KMS_KEY_ID` matched the historical KEY01 alias
- `AWS_KMS_KEY_ID` did not match the active KEY02 alias

No key values were printed.

The original uploaded file was not semantically rewritten.

## Private DR verification and restore

Outer encrypted DR archive:

`RUBY-ENVELOPE-VAULT-v0.1.6.1-PRIVATE-DR-PROMOTED-20261003T141227Z.tar.gz.age`

Results:

- outer age decrypt: PASS
- private DR internal manifest: PASS
- encrypted PostgreSQL backup SHA256: PASS
- database age decrypt: PASS
- restore into isolated recovery database: PASS
- restored users: 1
- restored vault items: 1
- restored vault item versions: 1
- restored key registries: 2
- restored audit events: 92

The isolated manual restore was intentionally run through the postgres local
socket. This made restored objects postgres-owned, so the app role initially
received `permission denied` on `key_registries`.

This was a property of the manual isolated restore path, not a defect in
`script/restore-db`. The canonical script restores through
`TARGET_DATABASE_URL`, so pg_restore executes as the target app role.

For this isolated acceptance DB only, schema/table/sequence privileges were
granted to `vault_user`.

## Active-key guard acceptance

A temporary external production env was generated with:

- restored production database
- uploaded AWS credentials
- `VAULT_KEY_PROVIDER=aws_kms`
- active alias normalized in the temporary env to KEY02

The original `ruby-encrypt-env` remained unchanged except for mode 0600.

A separate stale production env using KEY01 was then tested:

`STALE_ALIAS_START=BLOCKED`

This proves the Milestone 1/2 boot guard rejects the stale uploaded alias.

## Normalized AWS live acceptance

Using the temporary normalized production env:

- production boot: PASS
- `/up`: HTTP 200
- `/ready`: HTTP 200
- provider: aws_kms
- provider status: ready
- provider category: none
- provider remote: yes
- operator status: PASS
- current release remained `/content/RELEASE-0.1.6.1`

Because `/ready` invokes both provider availability and
`assert_write_allowed!`, HTTP 200 proves:

- AWS KMS remote key availability: PASS
- active KeyRegistry match: PASS
- write authorization guard: PASS

## Historical decrypt

The first restored Vault item was decrypted read-only.

Only the boolean result was emitted:

`HISTORICAL_AWS_KMS_DECRYPT=PASS`

No schema/title/password/plaintext was printed.

## Diagnostics bug found and fixed

While running production diagnostics on the notebook, `activate-runtime.sh`
used `ENV_FILE=/dev/null` to suppress DEV env loading.

The Milestone 3 versions of `key-provider-status` and `operator-status`
incorrectly treated any non-empty `ENV_FILE` as higher priority than the
explicit production selector.

Fix:

When any of the following is true:

- `RAILS_ENV=production`
- `PRODUCTION_ENV_FILE` is set
- `OPS_ENV_FILE` is set

the shared production resolver is now authoritative even if
`ENV_FILE=/dev/null` was used during runtime activation.

Post-fix:

- shell syntax: PASS
- production-env targeted tests: PASS
- provider status: ready
- operator status: PASS

## Post-fix regression

- Rails: 152 runs / 1387 assertions / 0 failures
- RuboCop: 164 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- security: 4 runs / 26 assertions / 0 failures

## Result

`DEV_0_1_7_FRESH_HOST_AWS_KMS_LIVE_ACCEPTANCE=PASS`
