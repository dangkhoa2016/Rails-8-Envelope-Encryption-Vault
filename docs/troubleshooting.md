# Troubleshooting — v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](troubleshooting.vi.md)

## Diagnostic rules

Begin by identifying your environment (CI, ordinary development, Kaggle/Colab, or production candidate), source SHA, Ruby version and the **first actual error**. Avoid changing multiple variables at once. Never paste raw `.env` contents, database URLs with passwords, KEKs, AWS tokens or decrypted vault data into reports.

## Common problems

| Symptom | Likely boundary to inspect | Safe first check |
| --- | --- | --- |
| Ruby/Bundler mismatch | `.ruby-version`, Bundler, native gems | `ruby -v`; `bundle check` |
| PostgreSQL connection refused | Service process, socket/port, `DATABASE_URL` | `./bootstrap.sh status` in notebook; `pg_isready` on a configured host |
| Rails migration error | Wrong database/environment or insufficient privileges | `bin/rails db:prepare` **only on a disposable DB** |
| KEK/provider unavailable | `VAULT_KEY_PROVIDER`, KEK ID/dir, KMS permissions | `script/key-provider-status`; inspect [Key management](KEY-MANAGEMENT.md) |
| Decrypt/authentication error | Wrong KEK, context/AAD or modified envelope | Stop writes; preserve backup; check source version and key mapping |
| Login rejected | Account not created, MFA, password or policy | Confirm safe owner creation and account policy without logging passwords |
| CSRF/host rejection | Reverse proxy, host allow-list, origin handling | Check actual hostname and approved proxy settings |
| Assets/UI missing | Runtime assets, Rails environment, proxy path | `./bootstrap.sh doctor` or deployment asset checks |
| Backup verification fails | Incomplete file, wrong checksum or age identity | `script/verify-backup` with a **copy**, not an irreplaceable original |
| DR rehearsal refuses target | Fresh-DB naming/safety guard or insufficient privileges | Check [Backup/restore](BACKUP-RESTORE.md) target rules |
| CI green but deployment fails | Runtime/host-specific configuration not exercised by CI | [Qualification](qualification.md) and [Deployment](deployment.md) |

## Step-by-step triage

1. **Freeze the evidence.** Record revision/SHA, UTC time, environment and sanitized error message.
2. **Scope the failure.** Does it affect installation, authentication, encryption, storage, network or recovery?
3. **Run non-destructive checks.** Use `./bootstrap.sh status`, `./bootstrap.sh doctor` or `script/ops-check` in an appropriately protected environment.
4. **Inspect configuration presence**, not secret values. Verify environment-variable names, file permissions and key identifiers without printing key bytes.
5. **Reproduce with synthetic data** in a separate development database and KEK directory.
6. **Collect redacted logs**, test command exit codes and known-good/known-bad SHA comparisons.
7. **Escalate safely.** For potential key leakage or security bypass, follow the [private security policy](SECURITY.md).

## Notebook recovery after restart

Kaggle/Colab may restart without notice. The bootstrap stores runtime outside Git in `/kaggle/working` or `/content` when available. If the filesystem was persisted, re-enter the repository and run:

```bash
source ./activate-runtime.sh
./bootstrap.sh status
./bootstrap.sh doctor
```

If runtime state is gone, provisioning must be repeated with **synthetic** secrets. A recreated container does not magically restore encrypted database content or its independent KEK; follow a validated backup recovery path instead of inventing a new key for old ciphertext.

## Recovery and rotation safety

- A stored wrapped DEK depends on its historical KEK. Do **not** delete old KEKs merely because a new active KEK exists.
- `script/verify-backup` can confirm wrapper integrity and restore metadata; actual DR acceptance needs fresh database restore **and canary decrypt**.
- Never point restore commands at a production source DB or disable the fresh-database name guards to make a test pass.
- If the GCM authentication check fails, investigate context, tampering and key mapping before taking corrective action; do not suppress the error.

## Useful next reads

[Notebook setup](KAGGLE-SETUP.md) · [Key management](KEY-MANAGEMENT.md) · [Backup and restore](BACKUP-RESTORE.md) · [Reproducibility](reproducibility.md) · [Security policy](SECURITY.md)

When submitting a bug, include the first sanitized error, minimal fake reproduction, affected command and exact commit SHA.
