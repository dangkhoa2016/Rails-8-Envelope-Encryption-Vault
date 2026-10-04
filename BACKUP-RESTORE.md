# Backup and Disaster Recovery — v0.1.2

## Preferred encrypted backup

Set an age recipient so the PostgreSQL dump is streamed directly into an encrypted artifact:

```bash
export DATABASE_URL='postgresql://...'
export BACKUP_AGE_RECIPIENT='age1...'
BACKUP_DIR=/secure/backups script/backup-db
```

The result is:

```text
ruby-envelope-vault-<UTC>.dump.age
ruby-envelope-vault-<UTC>.dump.age.sha256
```

The Vault KEK is deliberately excluded. Store KEK recovery copies separately from DB backups.

Before treating a deployment as operationally ready, load the deployment environment and run:

```bash
script/ops-check
```

For a strict production gate that requires both encrypted-backup configuration and live HTTPS smoke validation:

```bash
OPS_REQUIRE_BACKUP_CONFIG=1 OPS_REQUIRE_HTTPS_SMOKE=1 script/ops-check
```

The strict gate expects `BACKUP_AGE_RECIPIENT` and `APP_URL` to be provided by the deployment/backup job environment; it does not print either secret-bearing connection data or the age recipient value.

If `BACKUP_AGE_RECIPIENT` is unset, the script refuses to create a plaintext dump by default because that artifact still contains account metadata, password hashes, ciphertext and audit data. For a deliberately protected local-only dump, set `ALLOW_PLAINTEXT_BACKUP=1` explicitly.

## Verify

For encrypted backup:

```bash
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
script/verify-backup /secure/backups/ruby-envelope-vault-....dump.age
```

This verifies SHA-256, decryptability of the backup wrapper and the internal `pg_restore --list` catalog.

That is still not a DR PASS.

## Restore

```bash
TARGET_DATABASE_URL='postgresql://.../ruby_envelope_vault_dr_test' \
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
script/restore-db /secure/backups/ruby-envelope-vault-....dump.age
```

## Full acceptance: restore + decrypt

Use a known **fake** canary Vault item:

```bash
TARGET_DATABASE_URL='postgresql://.../ruby_envelope_vault_dr_test' \
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
USER_EMAIL='owner@example.com' \
ITEM_ID='<canary-item-uuid>' \
script/dr-verify /secure/backups/ruby-envelope-vault-....dump.age
```

The application must be started/executed with the matching recovery KEK directory. Only a successful decrypt of the restored canary is considered a recovery PASS.

## Repeatable DR rehearsal

For routine exercises, prefer the guarded orchestrator:

```bash
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
USER_EMAIL='owner@example.com' \
ITEM_ID='<canary-item-uuid>' \
EXPECTED_CANARY_FIELD='notes' \
EXPECTED_CANARY_VALUE='CANARY-FAKE-SECRET-123' \
script/dr-rehearsal /secure/backups/ruby-envelope-vault-....dump.age
```

It verifies the backup, creates a fresh database with the `ruby_envelope_vault_dr_` prefix, invokes the existing restore+decrypt verification, then drops the rehearsal database by default.

Safety rules:

- the target database must use the configured DR prefix;
- the source database is never accepted as the target;
- the canary field and exact expected value are required;
- application credentials are reused only for the fresh database itself; create/drop privileges come from the local PostgreSQL OS account or explicit `DR_ADMIN_DATABASE_URL`;
- set `KEEP_DR_DATABASE=1` only for deliberate inspection after a rehearsal.

## FIX8 operations contract

For machine-readable monitoring without exposing internal details through HTTP:

```bash
script/ops-report
```

For a scheduled encrypted backup + checksum/catalog verification run:

```bash
BACKUP_DIR=/secure/backups \
BACKUP_AGE_RECIPIENT='age1...' \
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
script/ops-maintenance
```

Add `RUN_DR_REHEARSAL=1` and the fake-canary variables to include a fresh-DB recovery rehearsal. The JSON report includes only timestamp, duration, status, backup basename/SHA-256, DR status, and retention status.

Retention is dry-run by default and keeps at least two backups:

```bash
BACKUP_DIR=/secure/backups RETENTION_KEEP=7 script/backup-retention
BACKUP_DIR=/secure/backups RETENTION_KEEP=7 RETENTION_APPLY=1 script/backup-retention
```

Only guarded `ruby-envelope-vault-*.dump.age` artifacts and their checksum sidecars are managed by default. DR cleanup failures are fatal and must never be reported as PASS.

## FIX9 offsite round-trip contract

Use the filesystem driver only for local semantic acceptance:

```bash
OFFSITE_DRIVER=filesystem \
OFFSITE_DEST_DIR=/separate/test/path \
script/offsite-roundtrip /secure/backups/ruby-envelope-vault-....dump.age
```

For a real offsite destination, use an already configured rclone remote:

```bash
OFFSITE_DRIVER=rclone \
OFFSITE_RCLONE_DEST='remote:vault-backups' \
script/offsite-roundtrip /secure/backups/ruby-envelope-vault-....dump.age
```

The command uploads the encrypted backup and checksum sidecar, retrieves both again, and compares the retrieved SHA-256 with the local artifact. A local filesystem adapter is never accepted by `REQUIRE_REAL_OFFSITE=1`.

## FIX11 portable offsite disaster recovery

New backups write checksum sidecars using only the backup basename, so the pair can be moved between hosts/directories without retaining a source-machine path.

`script/verify-backup` also verifies the exact file path supplied by the operator instead of delegating path resolution to the sidecar. This prevents a relocated artifact from accidentally validating an older file named by a legacy absolute-path sidecar.

For a full DR rehearsal starting from the real rclone remote:

```bash
OFFSITE_RCLONE_DEST='ruby-vault-offsite:ruby-envelope-vault' \
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
USER_EMAIL='owner@example.com' \
ITEM_ID='<fake-canary-item-uuid>' \
EXPECTED_CANARY_FIELD='notes' \
EXPECTED_CANARY_VALUE='CANARY-FAKE-SECRET-123' \
script/offsite-dr-rehearsal ruby-envelope-vault-YYYYMMDDTHHMMSSZ.dump.age
```

The command requires a configured non-local/non-memory/non-alias rclone remote, downloads the backup plus checksum into a fresh staging directory, verifies the downloaded bytes, invokes the guarded fresh-database DR rehearsal, and removes the staging directory by default. Use `KEEP_OFFSITE_DR_STAGE=1` only for deliberate inspection.
