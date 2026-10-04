# Build Validation — Ruby Envelope Vault v0.1.2-FIX7

**Date:** 2026-09-28  
**Release focus:** Kaggle / Dockerless full bootstrap

## Release objective

v0.1.2 keeps the v0.1.1 security-hardening work and adds a single root-level `bootstrap.sh` designed for Kaggle Notebook terminals where Docker and systemd must not be assumed.

The bootstrap installs/provisions mise, Ruby, PostgreSQL, Redis, build packages, gems, Vault key material, databases, tests and the Rails server using ordinary user-space processes.

## Validation executed in the build environment

### Crypto self-test

```text
14 runs
19 assertions
0 failures
0 errors
0 skips
```

PASS.

### Security/TOTP/.env self-test

```text
5 runs
12 assertions
0 failures
0 errors
0 skips
```

PASS.

### Repository policy

```text
PASS repository policy
```

PASS.

### Ruby syntax

95 Ruby/Rake source files were checked with `ruby -c`.

PASS.

### Shell syntax

All Bash entrypoints under `bin/`, `script/`, plus the new root `bootstrap.sh` were checked with `bash -n`.

PASS.

### YAML syntax

Parsed successfully:

- `compose.yaml`
- `config/deploy.yml`
- GitHub Actions workflow YAML

PASS.

### Bootstrap status-mode smoke

`./bootstrap.sh status` executed without modifying system services and correctly reported the build environment as uninitialized for PostgreSQL/Redis.

PASS.

### Docker/systemd independence check

The Kaggle `bootstrap.sh` contains no `docker`, `docker compose`, or `systemctl` command dependency.

PASS.

## Kaggle bootstrap capabilities integrated

`bootstrap.sh` now performs the following in one entrypoint:

1. chooses `/kaggle/working/.ruby-envelope-vault-runtime` when running on Kaggle;
2. checks available disk space;
3. installs build/runtime packages through apt;
4. attempts PostgreSQL 17 via the official PGDG apt repository;
5. falls back to the distro PostgreSQL package if PostgreSQL 17 is unavailable;
6. installs Redis server/client;
7. installs `age` when available;
8. installs mise in the writable Kaggle runtime directory;
9. installs/activates Ruby 3.4.11 through mise;
10. pins Bundler 2.6.9;
11. installs Ruby gems under the writable runtime directory;
12. creates a private PostgreSQL cluster rather than relying on a system service;
13. starts PostgreSQL using `pg_ctl`, not systemd;
14. configures TCP SCRAM-SHA-256 authentication;
15. creates a restricted application role and development/test DBs;
16. starts a localhost-only password-protected Redis instance from a private config;
17. automatically avoids occupied PostgreSQL/Redis ports;
18. persists generated runtime secrets in `.env.kaggle` mode 0600;
19. generates a Vault KEK outside the source tree;
20. runs Rails `db:prepare`;
21. builds Tailwind CSS without requiring Node/npm;
22. verifies the active KEK with a real encrypt/decrypt probe;
23. runs standalone crypto/security self-tests;
24. runs the Rails test suite by default;
25. optionally creates the first owner;
26. generates `activate-kaggle.sh` for subsequent terminals;
27. starts Rails on `0.0.0.0:3000` by default;
28. exposes setup/start/stop/status/doctor subcommands through the same file.

## Idempotence/safety measures

- existing `.env.kaggle` credentials are reused on reruns;
- existing mise/Ruby installations are reused;
- an existing PostgreSQL data directory is not reinitialized;
- an already-running managed PostgreSQL process is detected via `pg_ctl`;
- the PostgreSQL binary matching an existing data directory major version is preferred;
- an existing managed Redis process is reused when credentials match;
- a stale/mismatched managed Redis process is restarted using only its private runtime PID;
- KEKs are never overwritten automatically;
- generated application DB/Redis passwords use URL/config-safe characters;
- PostgreSQL role/database identifiers are validated before SQL use;
- owner password input supports an interactive prompt or a protected password file;
- `.env.kaggle`, `activate-kaggle.sh`, and local Kaggle runtime data are gitignored.

## What could not be honestly marked PASS here

This artifact was assembled in a general build container, not an actual Kaggle Notebook runtime. Therefore the following were **not** claimed as end-to-end PASS in this build environment:

- Kaggle apt installation;
- live PGDG repository access;
- mise download from `mise.run`;
- compiling/installing Ruby 3.4.11 through mise;
- Bundler network installation;
- live PostgreSQL cluster initialization under Kaggle's `postgres` OS account;
- live Redis daemon startup on Kaggle;
- Rails 8.1.4 boot using the downloaded bundle;
- full Rails integration tests against the Kaggle PostgreSQL cluster;
- browser access through a Kaggle-compatible tunnel.

The script deliberately fails with actionable messages when required Internet/package access is unavailable.

## Kaggle acceptance command

On Kaggle, the primary acceptance run is:

```bash
cd /kaggle/working/ruby-envelope-vault-v0.1.2
chmod +x bootstrap.sh
CREATE_OWNER=1 OWNER_EMAIL='you@example.com' START_SERVER=0 ./bootstrap.sh
source ./activate-kaggle.sh
./bootstrap.sh doctor
bin/rails test
bin/rails vault:keys:verify
```

Then start the server:

```bash
./bootstrap.sh start
```

## Kaggle runtime acceptance — 2026-09-27 FIX4

The actual Kaggle runtime has now proven the Dockerless stack substantially beyond the original build-container validation, including a later device/runtime switch that exposed persistence-mode drift and missing empty PostgreSQL directories:

- Ruby 3.4.11 and Bundler 2.6.9 active;
- PostgreSQL 17.11 private cluster running and database connection PASS;
- Redis 6.0.16 private instance running and connection PASS;
- Vault KEK is 32 bytes, mode 0600, and `vault:keys:verify` PASS;
- Zeitwerk eager loading PASS;
- full Rails suite: 42 runs / 160 assertions / 0 failures / 0 errors;
- headless-Chrome system suite: 5 runs / 33 assertions / 0 failures / 0 errors;
- browser flows cover unauthenticated redirect, login, vault create/edit/version restore, stale reauthentication, reveal, MFA TOTP login, one-time recovery-code login, MFA enrollment, recovery-code display, MFA disable and current-session revocation;
- recovery-code service regression proves accept-once/replay-reject behavior;
- request regression proves password → MFA challenge → recovery-code login;
- environment export acceptance proves attachment body/filename, `Cache-Control: no-store`, `Pragma: no-cache` and audit logging;
- IDOR acceptance returns 404 for another user's show, reveal, export, version index and version restore endpoints;
- key rotation tests: 2 runs / 13 assertions / 0 failures / 0 errors;
- RuboCop Rails Omakase: 114 files inspected / no offenses detected;
- Brakeman: 0 security warnings;
- bundler-audit: no vulnerabilities found against ruby-advisory-db updated 2026-09-27;
- development Puma booted and `/up` returned HTTP 200; unauthenticated `/` redirected to `/session/new` as expected;
- plaintext-canary proof: fake marker was not found in a PostgreSQL dump;
- age-encrypted backup created, SHA-256 verified and `pg_restore --list` validation passed;
- encrypted backup restored into fresh `ruby_envelope_vault_dr_acceptance` database;
- restored canary item decrypted successfully and exact `notes` marker comparison passed;
- negative DR assertion was verified: a deliberately wrong expected marker exits non-zero;
- restart self-heal PASS after device switch: executable bits restored for project scripts, mise Ruby, Selenium/Chrome and Bundler `bin/`/`exe/`; PostgreSQL 17 reinstalled from persisted `PG_VERSION`; PGDATA owner/mode and standard empty directories repaired; Redis restarted; Tailwind native binary executed; project doctor passed;
- Kaggle's `pkgconf` provider is preserved when already present, avoiding unrelated `r-base-dev` removal; the temporary host-package side effect discovered during testing was restored.



## FIX5 UI/View runtime acceptance — 2026-09-28

The FIX5 UI/View workstream was executed directly on Kaggle after reconnecting through multiple fresh notebook devices. Each restart used the FIX4 self-heal path rather than changing the proven runtime architecture.

Runtime-proven FIX5 behavior:

- shared vault create/edit form partial with unchanged encrypted-secret update semantics;
- archive/unarchive controls, state badges, audit events and cross-user authorization regression coverage;
- vault empty-state and safe non-secret metadata;
- encrypted-title search through POST body, with `q` filtered from Rails logs and absent from browser URLs;
- title matching only after current-user ciphertext is decrypted in memory with `audit: false`; no plaintext title column or search index was introduced;
- metadata filters for vault kind/archive state and pagination after title filtering;
- per-user audit-action filtering and pagination using the non-reserved `event_action` transport parameter;
- current-version UI marker, restore explanation and confirmation;
- current/active/revoked session UI states and revoke confirmation;
- password-change form labels, required/minlength constraints and help text;
- MFA recovery-code invalidation warning plus confirmation before disabling MFA.

Final FIX5 full CI:

```text
crypto self-test: 14 runs / 19 assertions / PASS
security self-test: 5 runs / 12 assertions / PASS
repository policy: PASS
Zeitwerk eager load: PASS
Rails suite: 47 runs / 181 assertions / 0 failures / 0 errors / 0 skips
System/browser suite: 5 runs / 54 assertions / 0 failures / 0 errors / 0 skips
RuboCop: 118 files inspected / 0 offenses
Brakeman: 0 security warnings
bundler-audit: no vulnerabilities found
```

FIX5 preserves the existing security boundary: titles, usernames, URLs, notes, environment values and secret material remain encrypted at rest. Search convenience does not add plaintext searchable columns.

## FIX6 operational-readiness runtime acceptance — 2026-09-28

FIX6 adds an operator-only readiness gate while preserving the public `/ready` endpoint as a minimal 200/503 signal.

Runtime-proven behavior:

- `script/ops-check` validates the required CLI toolchain, Rails production boot security checks, PostgreSQL connectivity and active Vault KEK verification without printing connection credentials;
- normal Kaggle operator run: production boot, database and KEK PASS; offsite backup recipient and HTTPS smoke explicitly SKIP when not configured;
- strict mode with `OPS_REQUIRE_BACKUP_CONFIG=1 OPS_REQUIRE_HTTPS_SMOKE=1` exits non-zero when `BACKUP_AGE_RECIPIENT` and `APP_URL` are absent;
- readiness request tests prove healthy DB+KEK returns HTTP 200;
- readiness failure returns HTTP 503 with an empty body and does not expose provider error details.

Final FIX6 full CI:

```text
crypto self-test: 14 runs / 19 assertions / PASS
security self-test: 5 runs / 12 assertions / PASS
repository policy: PASS
Zeitwerk eager load: PASS
Rails suite: 49 runs / 189 assertions / 0 failures / 0 errors / 0 skips
System/browser suite: 5 runs / 54 assertions / 0 failures / 0 errors / 0 skips
RuboCop: 119 files inspected / 0 offenses
Brakeman: 0 security warnings
bundler-audit: no vulnerabilities found
```

## FIX7 guarded DR rehearsal runtime acceptance — 2026-09-28

FIX7 turns the existing backup/restore primitives into a repeatable, guarded rehearsal workflow.

Runtime-proven FIX7 sequence:

- created a new fake canary item specifically for the rehearsal;
- created a fresh age-encrypted PostgreSQL backup with no intentional plaintext dump artifact;
- checksum and `pg_restore --list` catalog validation passed;
- `script/dr-rehearsal` created `ruby_envelope_vault_dr_20260928005415`;
- restore completed into that isolated database;
- exact canary decrypt passed for `notes=CANARY-FIX7-20260928`;
- the rehearsal reported PASS and automatically dropped its generated target database;
- an exact follow-up query confirmed the FIX7 target database no longer existed;
- forcing the source DB name as `DR_TARGET_DATABASE_NAME` failed closed before restore.

The pre-existing historical database `ruby_envelope_vault_dr_acceptance` was intentionally left untouched; FIX7 cleanup is scoped only to the database created by its own rehearsal.

Final FIX7 full CI:

```text
shell syntax gate: PASS
crypto self-test: 14 runs / 19 assertions / PASS
security self-test: 5 runs / 12 assertions / PASS
repository policy: PASS
Zeitwerk eager load: PASS
Rails suite: 49 runs / 189 assertions / 0 failures / 0 errors / 0 skips
System/browser suite: 5 runs / 54 assertions / 0 failures / 0 errors / 0 skips
RuboCop: 119 files inspected / 0 offenses
Brakeman: 0 security warnings
bundler-audit: no vulnerabilities found
```

## Security classification

v0.1.2-FIX7 is a **runtime-proven Kaggle bootstrap / production-security candidate**, not yet a production-ready release.

The Dockerless runtime foundation, core vault flows, MFA/recovery flows, export/IDOR controls, plaintext proof and DR are now runtime-proven on Kaggle. Remaining production work is deployment-specific: validate the intended Internet host/reverse proxy/TLS, independently custody production KEKs, verify operational monitoring and backups, and repeat restore/decrypt acceptance using the real deployment's backup path. Kaggle itself remains a development/demo environment because notebook persistence, network exposure and host lifecycle are outside this application's control.

## FIX8 deployment-operations acceptance — 2026-09-28

Runtime-proven on Kaggle after FIX7:

- bootstrap reconnect/self-heal persists `APP_HOSTS=localhost` for demo mode and restores `script/ops-check` PASS;
- `script/ops-report` emits safe JSON status without credentials, KEK paths, age identity/recipient, or canary plaintext;
- `script/backup-retention` dry-run and explicit apply both passed against isolated fake backup artifacts;
- `script/ops-maintenance` created a fresh age-encrypted backup, verified checksum/catalog, restored a guarded DR database, matched the exact FIX7 canary, cleaned the DR database, ran retention, and emitted a safe JSON report;
- corrupt checksum, wrong age identity, wrong canary, invalid DR target prefix, database-create failure, and cleanup failure all returned non-zero;
- cleanup failure now prints `FAIL cleanup` and is not masked.

Final FIX8 full gate:

```text
Crypto:         14 runs / 19 assertions / PASS
Security:       5 runs / 12 assertions / PASS
Repository:     PASS
Zeitwerk:       PASS
Rails:          49 runs / 189 assertions / PASS
System/browser: 5 runs / 54 assertions / PASS
RuboCop:        119 files / 0 offenses
Brakeman:       0 warnings
bundler-audit:  no vulnerabilities
FULL CI EXIT:   0
```

## FIX9 production-acceptance-kit validation — 2026-09-28

- filesystem offsite round-trip upload/retrieve/SHA-256 verification: PASS;
- KEK recovery-copy enumeration/fingerprint/permissions contract: PASS for one referenced Kaggle acceptance KEK;
- local production-acceptance composition: PASS with HTTPS intentionally SKIP;
- strict `REQUIRE_REAL_OFFSITE=1` with filesystem driver: FAIL as designed, requiring `OFFSITE_DRIVER=rclone`;
- Kaggle results are semantic/local acceptance only and are not evidence of a real Internet TLS endpoint, real offsite remote, or physically independent KEK custody.

Final FIX9 full gate:

```text
Crypto:         14 / 19 PASS
Security:       5 / 12 PASS
Repository:     PASS
Zeitwerk:       PASS
Rails:          49 / 189 PASS
System/browser: 5 / 54 PASS
RuboCop:        119 files / 0 offenses
Brakeman:       0 warnings
bundler-audit:  no vulnerabilities
FULL CI EXIT:   0
```

## FIX10 candidate external acceptance — 2026-09-28

Real public HTTPS endpoint exercised through Cloudflare Quick Tunnel:

```text
PASS production HTTPS/security-header/cache-control smoke
```

Strict production-acceptance result:

```text
PASS ops_check
PASS https_smoke
PASS kek_recovery_custody
PASS backup_verify
ERROR rclone remote is not configured: missingremote
FAIL offsite_roundtrip rclone
FAIL production acceptance contract
STRICT_PRODUCTION_EXIT=1
```

This is the intended fail-closed state. FIX10 is not complete until a real rclone remote passes the round-trip and KEK custody is independently operated rather than merely copied within the Kaggle runtime.

## FIX10 final strict acceptance — 2026-09-28

Configured real rclone remote:

```text
ruby-vault-offsite:
```

Strict offsite round-trip:

```text
PASS offsite round-trip
driver=rclone
backup=ruby-envelope-vault-20260928T012058Z.dump.age
sha256=0970b76412cad3a786659dfb07a32e850be574025fca0c6f2d2fe94c2909e725
```

Full strict acceptance:

```text
PASS ops_check
PASS https_smoke
PASS kek_recovery_custody
PASS backup_verify
PASS offsite_roundtrip rclone
PASS production acceptance contract
```

External HTTPS was exercised through a Cloudflare Quick Tunnel. This proves end-to-end TLS/security-header behavior but is not a durability claim for production hosting.

Final FIX10 full CI:

```text
Crypto:         14 / 19 PASS
Security:       5 / 12 PASS
Repository:     PASS
Zeitwerk:       PASS
Rails:          49 / 189 PASS
System/browser: 5 / 54 PASS
RuboCop:        119 files / 0 offenses
Brakeman:       0 warnings
bundler-audit:  no vulnerabilities
FULL CI EXIT:   0
```

## FIX11 portable offsite DR validation — 2026-09-28

Discovered during a real remote-download exercise: the legacy checksum sidecar stored the original absolute backup path. That could cause `sha256sum -c` after relocation to check the old source file rather than the downloaded artifact.

FIX11 validation:

```text
PORTABLE_CHECKSUM_ACCEPTANCE=PASS
CORRUPT_STAGED_EXIT=1
PORTABLE_NEW_BACKUP_SIDECAR=PASS

OFFSITE DR download backup=ruby-envelope-vault-20260928T012058Z.dump.age
PASS checksum/catalog validation
PASS DR restore+decrypt exact canary
PASS cleanup database
PASS offsite DR rehearsal
PASS cleanup offsite DR stage
```

The checksum sidecar on the real rclone remote was normalized to basename format.

Final FIX11 full gate:

```text
Crypto:         14 / 19 PASS
Security:       5 / 12 PASS
Repository:     PASS
Zeitwerk:       PASS
Rails:          49 / 189 PASS
System/browser: 5 / 54 PASS
RuboCop:        119 files / 0 offenses
Brakeman:       0 warnings
bundler-audit:  no vulnerabilities
FULL CI EXIT:   0
```

## FIX12 scheduled operations validation — 2026-09-28

Runtime-proven contracts on Kaggle:

```text
SCHEDULED_OPS_SYNTAX=PASS
LOCK_CONTENTION_EXIT=75
LOCK_ACCEPTANCE=PASS
FAILURE_RUN_EXIT=1
SAFE_ALERT_ACCEPTANCE=PASS
```

Real daily run:

```text
backup=ruby-envelope-vault-20260928T023452Z.dump.age
checksum/catalog verification=PASS
offsite round-trip rclone=PASS
retention=dry-run PASS
scheduled evidence status=pass
```

Real scheduled DR run:

```text
mode=dr
offsite_dr=pass
fresh database restore=PASS
exact canary decrypt=PASS
last-dr-success marker mode=0600
```

Kaggle does not provide a durable cron daemon, so only runner behavior is runtime-proven there. Cron/systemd templates are intended for persistent deployment hosts.

Final FIX12 full gate:

```text
Crypto:         14 / 19 PASS
Security:       5 / 12 PASS
Repository:     PASS
Zeitwerk:       PASS
Rails:          49 / 189 PASS
System/browser: 5 / 54 PASS
RuboCop:        119 files / 0 offenses
Brakeman:       0 warnings
bundler-audit:  no vulnerabilities
LOCK FILE MODE: 0600 PASS
FULL CI EXIT:   0
```

## FIX13 persistent scheduler deployment-kit validation — 2026-09-28

Kaggle staging-root validation proved:

```text
SYSTEMD_STAGING_ACCEPTANCE=PASS
CRON_STAGING_ACCEPTANCE=PASS
UNSAFE_PREFIX_EXIT=1
SECRET_EXCLUSION_AND_SYSTEMD_ACCEPTANCE=PASS
FIX13_SYSTEMD_STAGING=PASS
```

The staged systemd doctor verified the scheduler executable, env mode 0600, complete variable-name contract, runtime directories mode 0700, required tools, four unit/timer files, calendar expressions, `Persistent=true`, and non-live activation state.

The cron test preserved a pre-existing env sentinel while enforcing mode 0600 and rendered both daily and weekly DR commands. Secret-like test files were excluded from the staged release.

Kaggle does not activate the deployment-host scheduler; live service-account readability/writability and timer enablement remain fail-closed checks performed by the doctor on the persistent host.

Final FIX13 full gate:

```text
Crypto:         14 / 19 PASS
Security:       5 / 12 PASS
Repository:     PASS
Zeitwerk:       PASS
Rails:          49 / 189 PASS
System/browser: 5 / 54 PASS
RuboCop:        119 files / 0 offenses
Brakeman:       0 warnings
bundler-audit:  no vulnerabilities
FULL CI EXIT:   0
```


## FIX14 cross-host portability acceptance — 2026-09-28

Live migration/recovery acceptance on a clean 8 GiB E2B host exposed and proved fixes for real cross-host portability issues.

Runtime findings and fixes:

- FIX13 migration bundle integrity verified before restore.
- Clean-host FIX13 restore completed on E2B.
- Ruby 3.4.11 and the locked Rails bundle installed successfully.
- Kaggle-specific .bundle/config leaked into FIX13 migration source; FIX14 removes it and excludes .bundle from migration packaging.
- Eleven operational scripts restored with mode 0744 and failed for a non-root service account; FIX14 normalizes operational scripts to 0755 and the restore helper reapplies executable modes.
- DR local PostgreSQL socket default was Kaggle-specific; FIX14 defaults to /var/run/postgresql while preserving DR_LOCAL_PG_SOCKET override support.
- PostgreSQL 16 pg_restore could not read the current PostgreSQL 17 dump format; FIX14 verify-backup now reports the installed pg_restore version and recovery-tooling compatibility requirement. PostgreSQL 17.11 recovery tooling was runtime-proven.
- Real rclone offsite backup download and SHA-256/catalog verification passed.
- Fresh PostgreSQL 17 DR database restore passed.
- Rails recovery-KEK decrypt of item 7e431d43-f3a7-4c52-8f66-6943eea8158c passed with exact notes canary comparison.
- Manual scheduled daily run created ruby-envelope-vault-20260928T052823Z.dump.age, verified it, completed real rclone offsite round-trip after retry, and emitted status=pass evidence.

FIX14 regression gates:

- repository policy: PASS
- portability policy: PASS
- Zeitwerk eager load: PASS
- Rails tests: 49 runs / 189 assertions / 0 failures / 0 errors / 0 skips
- system/browser tests: 5 runs / 54 assertions / 0 failures / 0 errors / 0 skips
- RuboCop: 119 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no known vulnerabilities

