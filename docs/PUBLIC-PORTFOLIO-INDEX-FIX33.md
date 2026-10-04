# Public Portfolio Package Index — FIX33

Start here when reviewing the sanitized Ruby Envelope Vault portfolio package.

## Recommended review path

1. **README.md** — project goals, security model, product capabilities, deployment model, and release workflow.
2. **docs/ARCHITECTURE-OVERVIEW-FIX33.md** — Mermaid system, encryption, reveal, trust-boundary, and release-evidence diagrams.
3. **docs/ARCHITECTURE-THREAT-MODEL-FIX25.md** — threat model and trust assumptions.
4. **docs/PUBLIC-RELEASE-HISTORY.md** — sanitized release provenance and artifact integrity history.
5. **screenshots/** — synthetic-data UI evidence.

## Screenshot gallery

| View | File | What it demonstrates |
|---|---|---|
| Dashboard · desktop | `screenshots/01-dashboard-desktop.png` | overview and primary navigation |
| Vault · desktop | `screenshots/02-vault-desktop.png` | secret inventory and category-oriented UX |
| Item detail · desktop | `screenshots/03-item-detail-desktop.png` | protected-content detail surface |
| Version history · desktop | `screenshots/04-version-history-desktop.png` | immutable secret versions |
| Generator · desktop | `screenshots/05-generator-desktop.png` | browser-side secret generation |
| Audit · desktop | `screenshots/06-audit-desktop.png` | audit categories and event descriptions |
| Sessions · desktop | `screenshots/07-sessions-desktop.png` | active device/session management |
| Security · desktop | `screenshots/08-security-desktop.png` | MFA/security controls |
| Dashboard · mobile | `screenshots/09-dashboard-mobile.png` | responsive dashboard |
| Vault · mobile | `screenshots/10-vault-mobile.png` | responsive vault workflow |

Image dimensions and byte sizes are recorded in `screenshots/MANIFEST.tsv`. Individual screenshot hashes are recorded in `screenshots/SHA256SUMS.txt`.

## Safety boundary

This public package is allowlist-built and uses synthetic screenshots. It excludes environment files, KEKs, recovery keys, rclone configuration, database dumps, runtime state, and other secret-bearing material.
