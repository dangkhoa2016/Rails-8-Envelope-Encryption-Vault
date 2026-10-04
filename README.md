# Ruby Envelope Vault

A production-style Rails 8 personal secrets vault demonstrating envelope encryption, immutable secret history, MFA/session hardening, recovery discipline, and evidence-driven releases.

> **Current stable release:** `0.1.4`
> **Active development line:** `0.1.5-dev` (not promoted)  
> **Development baseline:** sealed stable `0.1.4`  
> **Upgrade baseline:** `0.1.2-FIX46`  
> **Security model:** server-side envelope encryption; **not** a zero-knowledge password manager.  
> **Demo rule:** public/demo deployments use synthetic data only.

## 0.1.5 development status

`0.1.5-dev` is a development-only fork of sealed stable `0.1.4`. Stable `RELEASE-0.1.4` remains immutable while portability, recovery and product-UX changes are validated in the separate development tree. The 0.1.5 line intentionally introduces no database migration and no change to the envelope-encryption/key-provider contracts.

Current 0.1.5 milestone evidence:

- [`docs/DEV-0.1.5-PORTABILITY-MILESTONE-2026-10-02.md`](docs/DEV-0.1.5-PORTABILITY-MILESTONE-2026-10-02.md)
- [`docs/DEV-0.1.5-PRODUCT-UX-MILESTONE-2026-10-02.md`](docs/DEV-0.1.5-PRODUCT-UX-MILESTONE-2026-10-02.md)
- [`docs/DEV-0.1.5-SECURITY-WORKSPACE-UX-MILESTONE-2026-10-02.md`](docs/DEV-0.1.5-SECURITY-WORKSPACE-UX-MILESTONE-2026-10-02.md)

## Why this project exists

Ruby Envelope Vault is designed as a portfolio-quality reference for building a secrets application where security claims are tied to explicit architecture and repeatable evidence rather than UI polish alone. It combines a modern Rails product surface with a release process that verifies encryption contracts, restoration, artifact integrity, and off-host recoverability.

## Security architecture

Each immutable secret version receives a fresh random 256-bit data-encryption key (DEK). The payload is encrypted with AES-256-GCM and authenticated additional data; the DEK is wrapped by a separate key-encryption key (KEK). PostgreSQL stores ciphertext, nonce, authentication tag, wrapped DEK, key identifier, and version metadata — not plaintext vault payloads or the KEK.

The default LocalFile KEK provider keeps key material outside PostgreSQL and outside Git. The provider contract is deliberately separable from encrypted-record schema so a future KMS-backed provider can implement the same wrap/unwrap boundary.

A fully authorized or compromised live Rails host with usable KEK access can decrypt records. The project therefore protects against a database-only disclosure and similar storage threats; it does not claim zero-knowledge properties.

## Product highlights

- purpose-built Login, Note, API Key, Environment and generic Secret flows;
- immutable version history with fresh per-version DEKs;
- sensitive-operation reauthentication;
- TOTP MFA, replay protection, encrypted pending/enabled seed, and bcrypt-hashed one-time recovery codes;
- session idle/absolute timeouts, active-device view and revocation;
- audit categories, friendly event descriptions and raw action identifiers;
- browser-side password/secret generator using Web Crypto;
- Tailwind CSS + Hotwire responsive UI with mobile/desktop regression coverage;
- synthetic-data demo mode warning;
- PostgreSQL backup/restore, optional `age` encryption and recovery helpers;
- Docker-free portable notebook/container bootstrap with self-healing PostgreSQL/Redis/tool runtime;
- release metadata, operator checklist, release history and off-host SHA-256 round-trip verification.

## Evidence-driven release workflow

The current workflow deliberately separates verification, promotion, and post-promotion evidence:

1. `script/release-seal-prepromote` runs repository/portability policy, Rails/system/security gates, builds canonical artifacts, checks source leakage, captures showcase screenshots, performs isolated restore and produces pre-promotion metadata.
2. The script stops at `PROMOTION_REQUIRED=yes`; it never changes the live release automatically.
3. Promotion of `current` and Puma restart are explicit operator actions.
4. `script/release-postpromote-evidence` verifies the promoted release, health and final metadata without mutating app state.
5. `script/release-checklist` and `script/release-history` produce operator-facing evidence.
6. Canonical artifacts and evidence are uploaded and downloaded back for SHA-256 verification.

## Documentation map

| Topic | Document |
|---|---|
| Architecture diagram & system flow | [`docs/ARCHITECTURE-OVERVIEW-FIX33.md`](docs/ARCHITECTURE-OVERVIEW-FIX33.md) |
| Architecture & security overview | [`docs/ARCHITECTURE-SECURITY-OVERVIEW-FIX23.md`](docs/ARCHITECTURE-SECURITY-OVERVIEW-FIX23.md) |
| Threat model & trust boundaries | [`docs/ARCHITECTURE-THREAT-MODEL-FIX25.md`](docs/ARCHITECTURE-THREAT-MODEL-FIX25.md) |
| Recovery observability | [`docs/RECOVERY-OBSERVABILITY-FIX27.md`](docs/RECOVERY-OBSERVABILITY-FIX27.md) |
| Machine-readable recovery diagnostics | [`docs/RECOVERY-DIAGNOSTICS-FIX28.md`](docs/RECOVERY-DIAGNOSTICS-FIX28.md) |
| Release workflow | [`docs/RELEASE-WORKFLOW-FIX31.md`](docs/RELEASE-WORKFLOW-FIX31.md) |
| Public release history | [`docs/PUBLIC-RELEASE-HISTORY.md`](docs/PUBLIC-RELEASE-HISTORY.md) |
| Public portfolio landing | [`docs/PUBLIC-PORTFOLIO-LANDING-FIX34.md`](docs/PUBLIC-PORTFOLIO-LANDING-FIX34.md) |
| 0.1.3 upgrade guide | [`docs/UPGRADE-0.1.2-FIX46-TO-0.1.3.md`](docs/UPGRADE-0.1.2-FIX46-TO-0.1.3.md) |
| 0.1.3 production-readiness matrix | [`docs/PRODUCTION-READINESS-0.1.3.md`](docs/PRODUCTION-READINESS-0.1.3.md) |
| 0.1.4 development roadmap | [`docs/ROADMAP-0.1.4.md`](docs/ROADMAP-0.1.4.md) |
| 0.1.6 development roadmap | [`docs/ROADMAP-0.1.6.md`](docs/ROADMAP-0.1.6.md) |
| 0.1.6 operator workflow | [`docs/OPERATOR-WORKFLOW-0.1.6.md`](docs/OPERATOR-WORKFLOW-0.1.6.md) |
| 0.1.4 operator workflow | [`docs/OPERATOR-WORKFLOW-0.1.4.md`](docs/OPERATOR-WORKFLOW-0.1.4.md) |
| 0.1.4 manual accessibility evidence | [`docs/MANUAL-ACCESSIBILITY-EVIDENCE-0.1.4.md`](docs/MANUAL-ACCESSIBILITY-EVIDENCE-0.1.4.md) |
| 0.1.6 manual accessibility review worksheet | [`docs/MANUAL-ACCESSIBILITY-EVIDENCE-0.1.6.md`](docs/MANUAL-ACCESSIBILITY-EVIDENCE-0.1.6.md) |
| 0.1.4 key-provider contract | [`docs/KEY-PROVIDER-CONTRACT-0.1.4.md`](docs/KEY-PROVIDER-CONTRACT-0.1.4.md) |
| 0.1.4 external KMS adapter contract | [`docs/EXTERNAL-KMS-ADAPTER-CONTRACT-0.1.4.md`](docs/EXTERNAL-KMS-ADAPTER-CONTRACT-0.1.4.md) |
| Public portfolio package index / screenshot gallery | [`docs/PUBLIC-PORTFOLIO-INDEX-FIX33.md`](docs/PUBLIC-PORTFOLIO-INDEX-FIX33.md) |
| Showcase workflow | [`docs/SHOWCASE-WORKFLOW-FIX25.md`](docs/SHOWCASE-WORKFLOW-FIX25.md) |
| Accessibility evidence boundary | [`docs/ACCESSIBILITY-MANUAL-EVIDENCE-FIX26.md`](docs/ACCESSIBILITY-MANUAL-EVIDENCE-FIX26.md) |

## Portfolio / demo deployment model

Use separate deployments:

1. **Public portfolio demo** — synthetic data only, demo banner enabled, no personal KEK or real credentials.
2. **Personal vault** — separate host/database/KEK, signup disabled, MFA required, recovery material backed up independently, and restore drills tested.

The sanitized public showcase package is intentionally allowlist-built and excludes environment files, KEKs, recovery keys, rclone configuration, database dumps, runtime state and other secret-bearing material.

## Current release quality

0.1.5 is the current sealed stable release. It preserves the accepted cryptographic, recovery, HTTP/security, failure-handling, logging-redaction, CSRF/origin, rate-limit, session-lifecycle and external-KMS boundaries while adding cross-cloud/container portability and production-facing Vault/Security workspace UX improvements. It introduced no database migration, Gemfile/lockfile change, route change, or encrypted-record/key-provider persistence change. The promoted release passed isolated new-host recovery, sealed-source verification, public-package integrity checks and a real off-host SHA-256 round trip. Manual accessibility evidence remains explicitly pending; no WCAG conformance claim is made.

## Notebook/container: one-command Docker-free setup

The root-level `bootstrap.sh` manages the full development/demo stack without requiring Docker or systemd. It supports Kaggle, Google Colab, and similar Debian/Ubuntu notebook or container hosts.

From the Kaggle terminal after uploading/extracting this repository:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

The script is idempotent and installs/configures:

- OS build dependencies through `apt`;
- `mise` under `/kaggle/working/.ruby-envelope-vault-runtime`;
- Ruby 3.4.11 through mise;
- Bundler + project gems;
- a private PostgreSQL cluster started with `pg_ctl` (no systemd);
- Redis started from a private config/pidfile (no systemd);
- `age` for encrypted database backups when available;
- a generated database role plus development/test databases;
- a 32-byte Vault KEK outside the project directory;
- `.env.kaggle` with mode `0600`;
- database migrations, Tailwind build and key verification;
- crypto/security self-tests, the Rails test suite and a headless-Chrome system smoke test by default;
- Chrome-for-Testing runtime libraries for Kaggle browser tests, with Selenium cache persisted under `/kaggle/working/.ruby-envelope-vault-runtime/selenium`;
- Rails server on `0.0.0.0:3000`.

To set up everything but not hold the terminal in the Rails server:

```bash
START_SERVER=0 ./bootstrap.sh
```

To skip the Rails test suite during a faster rerun:

```bash
RUN_TESTS=0 START_SERVER=0 ./bootstrap.sh
```

To create the first owner during setup:

```bash
CREATE_OWNER=1 OWNER_EMAIL='you@example.com' START_SERVER=0 ./bootstrap.sh
```

The script will prompt for the password when run in an interactive terminal. For notebook-cell automation, prefer `OWNER_PASSWORD_FILE=/secure/path` rather than placing a real password directly in the cell.

For a new Kaggle terminal after the first setup:

```bash
source ./activate-runtime.sh
./bootstrap.sh status
```

Service control uses the same single bootstrap file:

```bash
./bootstrap.sh start
./bootstrap.sh status
./bootstrap.sh doctor
./bootstrap.sh stop
```

Default writable runtime location:

```text
/kaggle/working/.ruby-envelope-vault-runtime/
├── bin/mise
├── mise/
├── bundle/
├── postgres/data/
├── redis/
└── keks/
```

Redis is provisioned and health-checked for Kaggle runtime/infrastructure experiments. The current Rails application itself still uses its existing Rails/Solid Cache design rather than requiring Redis for correctness. This keeps the vault functional even when Redis is unavailable in another deployment target.

**Kaggle is a development/demo environment, not the recommended location for irreplaceable production credentials.** Preserve PostgreSQL backups and KEKs independently before storing anything important.

## Fast local bootstrap

Activate the exact production Ruby baseline:

```bash
mise use ruby@3.4.11
ruby -v
```

Start PostgreSQL 17, then:

```bash
cp .env.example .env
bin/bootstrap
script/project-doctor
bin/dev
```

Open:

```text
http://localhost:3000
```

Create an owner without opening public registration. Interactive input is preferred so the password does not appear in shell history/process metadata:

```bash
ALLOW_SIGNUPS=false EMAIL='you@example.com' bin/rails vault:owner:create
```

For automation, place the password in a mode-0600 file and use `PASSWORD_FILE=/secure/path` rather than an inline shell value.

## Crypto/security self-tests without Rails boot

```bash
script/crypto-self-test
script/security-self-test
```

Expected for the source archive built on 2026-09-27:

```text
crypto:   14 runs, 19 assertions, 0 failures
security:  5 runs, 12 assertions, 0 failures
```

## MFA

Production personal-vault deployments should use:

```bash
REQUIRE_MFA=true
```

After login, open **Security → MFA**, confirm identity, add the shown TOTP secret to an authenticator, enter a valid code and store the recovery codes offline.

The TOTP seed itself is encrypted with the envelope-encryption engine. Pending enrollment seeds are stored encrypted server-side with a short expiry and are not placed in the cookie-backed Rails session. Accepted TOTP counters are recorded to reject replay within the validity window. Recovery codes are never stored plaintext; only bcrypt hashes are persisted.

## Session policy

Defaults:

```text
idle timeout:          20 minutes
absolute timeout:      12 hours
reauthentication:       5 minutes
pending MFA challenge:  5 minutes
```

Override through:

```text
SESSION_IDLE_TIMEOUT_MINUTES
SESSION_ABSOLUTE_TIMEOUT_HOURS
REAUTH_WINDOW_MINUTES
PENDING_MFA_TIMEOUT_MINUTES
```

Reveal is reauthentication-protected by default:

```bash
REAUTH_ON_REVEAL=true
```

## `.env` secrets

Create an item with kind `environment` and paste values such as:

```dotenv
DATABASE_URL=postgresql://...
OPENAI_API_KEY=...
HF_TOKEN=...
```

The whole structured payload is encrypted. Downloading `.env` is streamed from memory with `Cache-Control: no-store`; no plaintext temporary export is intentionally created.

## Key management

Generate a new local KEK:

```bash
bin/rails vault:keys:generate ID=kek-2026-01 DIR=/secure/vault/keks
```

Verify the active key:

```bash
VAULT_ACTIVE_KEK_ID=kek-2026-01 \
VAULT_KEK_DIR=/secure/vault/keks \
bin/rails vault:keys:verify
```

Dry-run key rotation:

```bash
VAULT_ACTIVE_KEK_ID=kek-2027-01 bin/rails vault:keys:rotate FROM=kek-2026-01 TO=kek-2027-01 DRY_RUN=1
```

Perform rewrap:

```bash
VAULT_ACTIVE_KEK_ID=kek-2027-01 bin/rails vault:keys:rotate FROM=kek-2026-01 TO=kek-2027-01
```

The operation unwraps each DEK with the old KEK, rewraps it with the new KEK, verifies the rewrap and updates only `wrapped_dek` + `kek_id`. The data ciphertext remains unchanged. Keep the old key until backup/restore verification succeeds.

## Prove plaintext is absent from PostgreSQL

Create a **fake** canary secret, then:

```bash
CANARY_SECRET='CANARY-FAKE-SECRET-123' \
DATABASE_URL="$DATABASE_URL" \
script/prove-no-plaintext
```

Expected:

```text
PASS: canary plaintext was not found in the database dump
```

## Backup

Encrypted backup with `age` is the default/recommended path:

```bash
BACKUP_AGE_RECIPIENT='age1...' \
DATABASE_URL="$DATABASE_URL" \
script/backup-db
```

A plaintext PostgreSQL dump is refused unless you explicitly acknowledge it:

```bash
ALLOW_PLAINTEXT_BACKUP=1 DATABASE_URL="$DATABASE_URL" script/backup-db
```

Verify an encrypted backup:

```bash
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
script/verify-backup backups/ruby-envelope-vault-....dump.age
```

The KEK is intentionally excluded from DB backup artifacts. Store a recovery copy separately.

## Disaster-recovery acceptance

A backup is not considered proven until a fresh database restore can decrypt a known fake canary item.

```bash
TARGET_DATABASE_URL='postgresql://.../fresh_restore' \
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
USER_EMAIL='you@example.com' \
ITEM_ID='<fake-canary-vault-item-uuid>' \
EXPECTED_CANARY_FIELD='notes' \
EXPECTED_CANARY_VALUE='CANARY-FAKE-SECRET-123' \
script/dr-verify backups/ruby-envelope-vault-....dump.age
```

Expected final line:

```text
PASS DR restore+decrypt ...
```

For a safer repeatable rehearsal, let the orchestrator create an isolated fresh database, run the same exact-canary verification, and clean the rehearsal database automatically:

```bash
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
USER_EMAIL='you@example.com' \
ITEM_ID='<fake-canary-vault-item-uuid>' \
EXPECTED_CANARY_FIELD='notes' \
EXPECTED_CANARY_VALUE='CANARY-FAKE-SECRET-123' \
script/dr-rehearsal backups/ruby-envelope-vault-....dump.age
```

The target database name is generated with the `ruby_envelope_vault_dr_` prefix. The script refuses the source database as a target. Outside a local PostgreSQL OS-account environment, provide `DR_ADMIN_DATABASE_URL` for create/drop privileges. Set `KEEP_DR_DATABASE=1` only when deliberately retaining the restored database for inspection.

## Operations reporting and scheduled maintenance

Machine-readable operator status is available without adding detail to the public `/ready` response:

```bash
script/ops-report
```

The JSON contains only safe status metadata: schema, timestamp, overall status, duration, per-check PASS/FAIL/SKIP states, and optional backup basename/SHA-256. It intentionally excludes database URLs, KEK paths, age identities/recipients, and canary plaintext.

A cron/systemd/Kamal hook can run the encrypted maintenance pipeline:

```bash
BACKUP_DIR=/secure/backups \
BACKUP_AGE_RECIPIENT='age1...' \
BACKUP_AGE_IDENTITY=/secure/recovery.agekey \
script/ops-maintenance
```

Set `RUN_DR_REHEARSAL=1` plus the existing fake-canary variables to include a guarded restore/decrypt drill. Retention runs in dry-run mode by default; choose a minimum of two retained backups with `RETENTION_KEEP`, and set `RETENTION_APPLY=1` only after reviewing the listed candidates.

```bash
BACKUP_DIR=/secure/backups RETENTION_KEEP=7 script/backup-retention
BACKUP_DIR=/secure/backups RETENTION_KEEP=7 RETENTION_APPLY=1 script/backup-retention
```

By default retention only manages files matching `ruby-envelope-vault-*.dump.age` plus their checksum sidecars. Plaintext dumps require the separate explicit `RETENTION_INCLUDE_PLAINTEXT=1` opt-in.

For strict production acceptance, `REQUIRE_REAL_OFFSITE=1` requires a named configured `rclone` remote and rejects local/memory/alias backends. External TLS can be validated through `APP_URL` + `script/production-smoke`, but temporary tunnel services are evidence of HTTPS behavior rather than proof of durable production hosting.

## Docker production-like demo

The Compose web service runs Rails production configuration but defaults to `DEMO_MODE=true`, `FORCE_SSL=false`, and signup disabled so it can be exercised locally without pretending local HTTP is a real production deployment.

Generate values first:

```bash
export POSTGRES_PASSWORD="$(openssl rand -hex 24)"
export SECRET_KEY_BASE="$(openssl rand -hex 64)"
export VAULT_KEK_HOST_DIR="$PWD/.local/keks"
export VAULT_ACTIVE_KEK_ID=kek-dev-01
mkdir -p "$VAULT_KEK_HOST_DIR"
chmod 700 "$VAULT_KEK_HOST_DIR" 2>/dev/null || true
[ -f "$VAULT_KEK_HOST_DIR/$VAULT_ACTIVE_KEK_ID.key" ] || \
  openssl rand 32 > "$VAULT_KEK_HOST_DIR/$VAULT_ACTIVE_KEK_ID.key"
chmod 600 "$VAULT_KEK_HOST_DIR/$VAULT_ACTIVE_KEK_ID.key"
# Linux production note: the non-root container runs as UID/GID 1000.
# Ensure UID 1000 can traverse/read the mounted KEK directory/file.
docker compose up --build
```

For a real Internet deployment use Kamal/reverse-proxy HTTPS with:

```text
DEMO_MODE=false
ALLOW_SIGNUPS=false
REQUIRE_MFA=true
REAUTH_ON_REVEAL=true
FORCE_SSL=true
APP_HOSTS=vault.example.com
```

See `config/deploy.yml` and `PRODUCTION-CHECKLIST.md`.

## CI/security gates

```bash
bin/ci
```

Runs crypto/security self-tests, PostgreSQL Rails tests, headless-Chrome system tests, RuboCop, Brakeman and bundler-audit. GitHub Actions also checks Ruby compatibility and performs a cold Docker build.

## Build-validation note

The original v0.1.2 archive was assembled without a full Rails/PostgreSQL runtime. FIX1–FIX4 were then exercised on actual Kaggle Notebook runtimes with Ruby 3.4.11, PostgreSQL 17.11 and Redis 6.0.16, including a device/runtime restart where persistent executable bits and empty PostgreSQL directories had to be self-healed.

Runtime-proven on Kaggle now includes Zeitwerk eager loading; 49 Rails tests / 189 assertions; 5 headless-Chrome system tests / 54 assertions covering login, vault create/edit/version restore, reauthentication/reveal, MFA TOTP/recovery-code login, MFA enrollment/disable and session revocation; `.env` export and IDOR request acceptance; clean RuboCop across 119 files; Brakeman with zero warnings; bundler-audit with no known vulnerabilities; KEK verification; plaintext-canary dump proof; age-encrypted backup verification; fresh-database restore+decrypt with exact canary matching; operational readiness gating; and restart self-heal for PostgreSQL/Redis/Ruby/Selenium/Bundler executable-mode drift.

This still does not make Kaggle a recommended production host. Before storing real credentials, complete the broader `PRODUCTION-CHECKLIST.md` against the intended deployment, independently custody production KEKs, and repeat restore/decrypt drills using the real deployment backup path.

## Documentation

- `THREAT-MODEL.md`
- `KEY-MANAGEMENT.md`
- `BACKUP-RESTORE.md`
- `PRODUCTION-CHECKLIST.md`
- `BUILD-VALIDATION-2026-09-27.md`
- `docs/MASTER-IMPLEMENTATION-PLAN-v1-2026-09-27.md`

## Scheduled operations and alerting

FIX12 adds a scheduler-safe entrypoint:

```bash
script/scheduled-ops daily
script/scheduled-ops dr
```

`daily` performs the encrypted backup/verify/offsite/retention pipeline and writes a minimal JSON evidence record. `dr` selects the newest encrypted backup from the configured real rclone destination and performs the full offsite disaster-recovery rehearsal.

The runner uses a non-blocking `flock`; a concurrent invocation exits 75 rather than overlapping backup or restore operations.

Failure alerts can be written to a protected JSONL file and/or posted to a webhook:

```bash
OPS_ALERT_FILE=/var/log/ruby-envelope-vault/ops-alerts.jsonl
OPS_ALERT_WEBHOOK_URL=https://alerts.example.invalid/webhook
```

Alert and evidence records intentionally omit credentials, database URLs, key paths, age identities/recipients, and canary plaintext.

Deployment templates are in `ops/`:

- `ops/ops.env.example`
- `ops/cron.example`
- `ops/systemd/ruby-envelope-vault-ops-daily.{service,timer}`
- `ops/systemd/ruby-envelope-vault-dr.{service,timer}`

The example cadence is a daily maintenance run at 02:15 UTC and a weekly offsite DR rehearsal at 03:30 UTC on Sunday. Kaggle is used to runtime-prove the commands only; it is not treated as a durable scheduler host.

## Persistent scheduler host deployment

FIX13 turns the scheduler templates into an installable deployment contract.

Stage or install systemd assets:

```bash
sudo OPS_SERVICE_USER=ruby-vault \
  script/install-ops-scheduler systemd
```

The installer intentionally does **not** enable timers by default. After editing `/etc/ruby-envelope-vault/ops.env`, installing the recovery age identity, Vault KEK and service-account-readable rclone config, run:

```bash
sudo script/ops-scheduler-doctor systemd
```

Only after the live doctor is clean:

```bash
sudo OPS_INSTALL_ENABLE=1 script/install-ops-scheduler systemd
```

Cron hosts can use:

```bash
sudo script/install-ops-scheduler cron
sudo script/ops-scheduler-doctor cron
```

Important: `RCLONE_CONFIG` is explicit in the scheduler environment. Do not rely on a root user's `~/.config/rclone/rclone.conf` when the scheduled job runs as a dedicated service account.

For CI/staging validation without touching the host:

```bash
stage="$(mktemp -d)"
OPS_INSTALL_ROOT="$stage" script/install-ops-scheduler systemd
OPS_INSTALL_ROOT="$stage" script/ops-scheduler-doctor systemd
rm -rf "$stage"
```

## FIX25 showcase and verification

FIX25 adds a fully synthetic, reproducible portfolio workflow:

- [Showcase workflow](docs/SHOWCASE-WORKFLOW-FIX25.md)
- [Architecture & threat model](docs/ARCHITECTURE-THREAT-MODEL-FIX25.md)
- [Accessibility verification](docs/ACCESSIBILITY-VERIFICATION-FIX25.md)

Useful commands:

```bash
./script/capture-showcase
./script/accessibility-smoke
```

The showcase fixture uses the real envelope-encryption path but contains fake values only.

