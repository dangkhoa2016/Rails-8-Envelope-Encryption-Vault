# Evidence index and interpretation — v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](evidence-index.vi.md)

## Purpose

This index identifies **where reviewable evidence comes from**, what it can substantiate, and what it cannot. It intentionally avoids claiming that the repository includes personal recovery material, production credentials, private logs or a certification report.

## Evidence sources

| Evidence | Location | Supports | Does not establish |
| --- | --- | --- | --- |
| Versioned implementation | `app/`, `db/`, `lib/` | Inspection of crypto, access and persistence contracts | Live-host security or correctness beyond tested paths |
| Automated tests | `test/` | Exercised behavior with controlled input | Exhaustive coverage or independent audit |
| Source checks | [CI workflow](../.github/workflows/ci.yml) | Lint, static security, Rails test paths, Ruby matrix and Docker build | Production deployment or an SLA |
| Documentation validation | [Docs workflow](../.github/workflows/docs.yml) and `script/doc-quality-check` | EN/VI parity and relative-link integrity | Technical accuracy of every operational assumption |
| Key lifecycle | `lib/tasks/vault_keys.rake`, `script/kek-recovery-check` | Key command contracts and separate-custody checks | Recovery of a particular lost production KEK |
| Backup and DR | `script/backup-db`, `script/verify-backup`, `script/dr-rehearsal` | Executable encrypted-backup and canary-restore procedures | Offsite retrieval and successful restore on an untested deployment |
| Host acceptance | `script/live-host-acceptance`, `script/production-acceptance` | Defined operational checks | Proof that those checks ran on the user's host |
| Accessibility | `test/system/`, [Test plan](ACCESSIBILITY-TEST-PLAN.md) | Automated checks and required human review steps | Formal WCAG conformity |

## Verify automated results

1. Resolve the exact release: `git rev-parse HEAD` and `git rev-parse v1.0.0^{}`.
2. Check that [GitHub Actions](https://github.com/dangkhoa2016/Rails-8-Envelope-Encryption-Vault/actions) shows completed jobs for the **same SHA**.
3. Inspect job logs for retries, skipped steps and environmental assumptions.
4. Confirm the workflow head SHA; results for other revisions do not validate the source under review.
5. Report the specific status: **PASS**, **FAIL**, **NOT RUN**, or **PENDING**. Do not replace missing evidence with optimistic text.


## Synthetic recovery evidence

A credible recovery rehearsal includes:

- Encrypted archive identity, SHA-256 verification and successful wrapper decryption.
- Download from the intended offsite location, not merely re-reading a local file.
- Restore to a separately named guarded database; source database remains untouched.
- Independently recovered age identity and KEKs still referenced by the archive.
- Successful decrypt of an **exact fictional canary**, and cleanup of the rehearsal environment.
- Scrubbed logs and an operator judgment that matches the evidence.

A checksum-only check and a successful `pg_restore --list` are useful partial tests, **not** a complete DR acceptance.

## Explicitly excluded from public evidence

- Raw Vault KEKs, AWS credentials, API tokens, private age identities and passwords.
- Personal ciphertext archives, private PostgreSQL data and real login details.
- Private infrastructure addresses, incident logs or unapproved account material.
- A claim that a security audit, penetration test, certification or production promotion happened without separately inspectable evidence.

See the [Qualification matrix](qualification.md), [Reproducibility guide](reproducibility.md) and [Production checklist](PRODUCTION-CHECKLIST.md).

## Reviewer checklist

```text
Revision/tag and commit SHA:
CI status and run URL:
Test scope / version matrix:
Documentation and links:
Synthetic DR evidence reference (no secrets):
Live-host evidence reference or PENDING:
Known exclusions, risks and operator approval:
```

Never attach sensitive artifacts to a public issue merely to prove a PASS.
