# Recovery provenance — 1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](RECOVERY-PROVENANCE.vi.md)
## What recoverability proves

A database archive alone is insufficient. Verify its checksum, decrypt the archive wrapper, restore into a fresh guarded database, and decrypt an **exact known synthetic canary** with independently retained recovery KEK material.

The repository provides backup, offsite retrieval, safeguarded restore and evidence reporting tools. Tests on a different host do not establish production acceptance for a new deployment.

## Evidence handling

Keep archives, key material, identities and sensitive host records outside Git. Publish only non-sensitive summaries and verified checksums. See [backup and restore](BACKUP-RESTORE.md) and [production checklist](PRODUCTION-CHECKLIST.md).
