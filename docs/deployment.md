# Deployment and operational acceptance — v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](deployment.vi.md)

## Release versus deployment

The `v1.0.0` tag identifies source code. **It is not approval to host real secrets.** A deployment must establish and test its own trust boundaries, including HTTPS, key custody, backups, recovery, identity policy and maintenance.

## Environment separation

| Environment | Permitted purpose | Data and key rules |
| --- | --- | --- |
| Development | Code changes, local UI and debugging | Synthetic credentials; local-only disposable KEKs |
| CI/test | Repeatable Rails/system/security checks | Ephemeral database and generated test KEK |
| Notebook demo | Kaggle/Colab demonstrations | Synthetic secrets; assume runtime can disappear |
| Production candidate | Operator-controlled infrastructure | Private TLS/domain, independent KEK and age recovery custody; explicit approval required |

The files `../ops/production.env.example` and `../config/deploy.yml` are **templates with placeholders**, not launch-ready credentials or an approved deployment architecture.

## Before provisioning

1. Pin the reviewed tag/SHA, Ruby runtime and PostgreSQL 17.
2. Configure a dedicated database identity and restrictive access to storage and backups.
3. Choose `local_file` or AWS KMS provider deliberately; document KEK recovery ownership separately from database administrators.
4. Provision external TLS termination, a reverse proxy and correct Rails hosts/origin/CSRF settings.
5. Define account registration restrictions, MFA requirements, reauthentication, session expiry and rate limiting.
6. Establish logs, monitoring, alerting, patching and a tested rollback strategy.
7. Configure an **age-encrypted** database backup schedule and independent offsite retrieval.
8. Verify that no personal KEK, recovery identity or credentials are checked into the source tree.

## Deploy and preflight

Use the appropriate infrastructure-specific scripts rather than directly copying the example files. Inspect the relevant `script/production-*`, `script/ops-*` and `script/live-host-acceptance` implementations before running them on an actual host.

At minimum, confirm:

- Rails boots in the intended environment and connects to the intended database.
- The configured KeyProvider can unwrap **synthetic** canary content with the expected key ID.
- TLS, domain/host authorization, origin handling and request forgery protections work through the actual reverse proxy.
- Sign-in, MFA challenge, reauthentication, session revocation and authorized reveal operate against synthetic users.
- Unexpected errors and audit events do not log plaintext secrets, passwords, KEKs or recovery identities.
- Backup and scheduler jobs use least-privilege credentials and report failures clearly.

For preliminary, non-destructive diagnostics (after loading a protected environment):

```bash
script/ops-check

# Strict gate when these deployment features have been configured:
OPS_REQUIRE_BACKUP_CONFIG=1 OPS_REQUIRE_HTTPS_SMOKE=1 script/ops-check
```

These checks are **preconditions**, not a final deployment sign-off. Confirm each script's required environment variables in the source first.

## Disaster recovery acceptance

1. Produce an age-encrypted PostgreSQL backup with `script/backup-db`.
2. Record the checksum and independently retrieve the encrypted archive from offsite storage.
3. Verify the archive using `script/verify-backup`.
4. Recover the necessary age identity and KEK material **from separately controlled custody**.
5. Restore into a new guarded database with `script/restore-db` or the rehearsal orchestrator.
6. Verify an exact fictional canary decrypts using `script/dr-verify` / `script/dr-rehearsal`.
7. Verify the production source DB was not modified during the exercise and store sanitized evidence.

**Checksum PASS is not DR PASS.** See the [Backup and restore guide](BACKUP-RESTORE.md) for command parameters, safety gates and examples.

## Final host acceptance checklist

| Gate | Required evidence |
| --- | --- |
| Identity | Synthetic account login, MFA and session lifecycle |
| Cryptography | KEK read/unwrap and canary reveal on the live host |
| Transport | HTTPS, correct proxy headers and safe host/origin validation |
| Storage | Restricted PostgreSQL and encrypted backup destinations |
| Recovery | Downloaded offsite archive → fresh DB restore → canary decrypt |
| Monitoring | Alert path, scheduled jobs, scrubbed logs and error handling |
| Accessibility | Human evaluation of keyboard, focus, contrast, screen readers and touch |
| Operator decision | Recorded approval, release SHA, host identity and rollback plan |

Do not claim production approval until every mandatory gate for that host has evidence. After any application, key, backup or infrastructure change, re-evaluate the affected controls.

## Related material

[Production checklist](PRODUCTION-CHECKLIST.md) · [Security](SECURITY.md) · [Key management](KEY-MANAGEMENT.md) · [Qualification](qualification.md) · [Qualification matrix](qualification.md) · [Troubleshooting](troubleshooting.md)
