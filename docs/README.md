# Documentation guide — Rails 8 Envelope Encryption Vault v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](README.vi.md)

## Find the right starting point

The top-level [README](../README.md) introduces the vault, envelope encryption and safe demo commands. This index is organized by **reader objective** rather than file count.

| Reader / goal | Start here | Continue with |
| --- | --- | --- |
| First-time evaluator | [Main README](../README.md) | [Engineering overview](engineering-overview.md) |
| Security reviewer | [Threat model](THREAT-MODEL.md) | [Key management](KEY-MANAGEMENT.md), [Architecture](ARCHITECTURE.md) |
| Application developer | [Architecture](ARCHITECTURE.md) | [Reproducibility](reproducibility.md), [Troubleshooting](troubleshooting.md) |
| Demo operator | [Notebook setup](KAGGLE-SETUP.md) | [Accessibility](ACCESSIBILITY.md) |
| Production operator | [Deployment](deployment.md) | [Production checklist](PRODUCTION-CHECKLIST.md) |
| DR reviewer | [Backup and restore](BACKUP-RESTORE.md) | [Recovery provenance](RECOVERY-PROVENANCE.md) |
| Source reviewer | [Qualification matrix](qualification.md) | [Evidence index](evidence-index.md), [Production checklist](PRODUCTION-CHECKLIST.md) |

## Architecture and engineering

- [Architecture](ARCHITECTURE.md): browser/Rails/database/KeyProvider boundaries and envelope lifecycle.
- [Engineering overview](engineering-overview.md): component map, service responsibilities and operational decisions.
- [Vault Search performance](VAULT-SEARCH-PERFORMANCE.md): correct encrypted search, pagination, KMS tradeoffs and reproducible synthetic benchmark.
- [Audit Activity Center](AUDIT-ACTIVITY.md): account-only event scope, outcomes, filters and limits of the security evidence.
- [Threat model](THREAT-MODEL.md): attackers, secrets, controls and excluded guarantees.
- [Key management](KEY-MANAGEMENT.md): KEK generation, rotation, rollback and independent custody.

## Setup, operations and disaster recovery

- [Notebook setup](KAGGLE-SETUP.md): ephemeral Kaggle/Colab bootstrap with synthetic data.
- [Deployment guide](deployment.md): environment separation, preflight and explicit host acceptance.
- [Modal dual deployment](MODAL-DEPLOYMENT.md): disposable public demo and isolated private PostgreSQL persistence.
- [Production checklist](PRODUCTION-CHECKLIST.md): go-live safeguards and operator responsibilities.
- [Backup and restore](BACKUP-RESTORE.md): age-encrypted dump, checksum, guarded restore and canary.
- [Recovery provenance](RECOVERY-PROVENANCE.md): recovery evidence expectations.
- [Troubleshooting](troubleshooting.md): safe diagnosis without disclosing secrets.

## Verification, accessibility and release

- [Reproducibility](reproducibility.md): clean checkout, CI and local test paths.
- [Qualification matrix](qualification.md): which PASS is source-only versus host-specific.
- [Evidence index](evidence-index.md): reviewable artifacts, exclusions and reporting template.
- [Accessibility](ACCESSIBILITY.md) and [manual test plan](ACCESSIBILITY-TEST-PLAN.md): explicit test scope and pending evidence.
- [Community maintenance guide](COMMUNITY.md): contribution, support, vulnerability reporting, issues and pull requests.
- [Changelog](CHANGELOG.md), [Security policy](SECURITY.md), [Contribution guide](../.github/CONTRIBUTING.md).

## Security and evidence conventions

Only synthetic credentials belong in examples, public screenshots or issue reports. Document a **source SHA**, not just a version name. If a test was not run, record **PENDING / NOT RUN**; do not turn a green source CI run into a production claim.

Every Markdown document has an English/Vietnamese counterpart and a language switch.
