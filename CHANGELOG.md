## 0.1.6.1-dev — AWS KMS Production Boot Hotfix

- Fixes a stale LocalFile-only production boot guard discovered by exact 0.1.6 DR recovery.
- Preserves LocalFile KEK file validation unchanged.
- Allows `VAULT_KEY_PROVIDER=aws_kms` when active key id and AWS region are configured.
- Stops AWS KMS production boot from incorrectly requiring a local `<kek-id>.key` file.
- Unknown providers remain fail-closed.
- Fresh-host restored historical AWS KMS decrypt through the default Registry: PASS.
- Full verification: Rails 137/1299; system 21/192; accessibility 52/991; RuboCop 160/0; Brakeman 0; bundler-audit clean; crypto 42/108; security 5/12.

## 0.1.6-dev — Development Line Opened

- Forked from sealed stable `0.1.5`; stable `current` remains on `RELEASE-0.1.5`.
- Opens a new development line without modifying accepted release source.
- Baseline verification: Rails 126/1111 PASS; system 20/183 PASS; RuboCop 158/0; Brakeman 0; bundler-audit clean; crypto 36/70 PASS; security 5/12 PASS; accessibility 47/845 PASS.
- Milestone 1 reconciles repository release truth/provenance before introducing new product scope.
- Manual accessibility human review was completed with no blockers reported; granular assistive-technology checks are not separately claimed and no WCAG conformance claim is implied.
- Reconciles stale AWS KMS development documentation with stable 0.1.4 authority: `aws_kms` Registry support is already accepted; additional outage/recovery/rollback drills remain future hardening.
- Manual review fixes: redesigns the Login glyph as a compact sign-in doorway/arrow icon, improves spacing between Protected details rows on vault-item edit forms, and changes Referrer-Policy from `no-referrer` to `same-origin` so same-origin POST search requests retain provenance for Rails origin-based CSRF validation without disabling origin checks.
- Responsive Dashboard hardening: delays the Recently updated/sidebar split until 1536px, protects Security posture status controls from wrapping, and adds 1365px viewport regression coverage.
- KMS rotation hardening: wraps the mutation phase in a new database transaction under the existing advisory lock so a provider outage cannot leave partially rewrapped records; adds a mid-rotation ExternalKms outage regression proving full rollback and secret-safe failure auditing.
- KMS operator diagnostics: adds a secret-safe provider readiness surface and integrates it into `operator-status`; expired credentials, access denied, wrap/unwrap outages and unknown-provider names are reduced to coarse safe statuses without leaking key IDs, ARNs, regions or credential material.
- AWS KMS fresh-host rehearsal: synthetic contract plus live AWS readiness/smoke/two-key rewrap/historical decrypt/Vault rotation all PASS on the restored Colab host; live-KMS Ruby scripts now explicitly load `bundler/setup` so direct execution resolves AWS SDK gems portably.

## 0.1.5 — Portability and Product UX Hardening

- Forked from sealed stable `0.1.4`; stable source remains immutable.
- Added portable runtime activation for Kaggle, Google Colab and generic XDG/HOME Linux environments while retaining `activate-kaggle.sh` as a compatibility wrapper.
- Hardened Ubuntu 24.04 package selection with `libasound2t64` / `libasound2` fallback.
- Fixed PostgreSQL Unix-socket provisioning when bootstrap selects a non-default port after collision; Redis/PostgreSQL collision recovery is now runtime-proven.
- Removed source-local Bundler configuration side effects and made new-host recovery independent of `/mnt/workspace` and mandatory tmux.
- Improved migration-bundle portability and recovery contracts.
- Added category guidance, clearer create/edit information architecture, template guidance, lifecycle clarity, accessible filter labels and active-filter recovery.
- Fixed POST search/filter behavior where Turbo Stream requests could leave stale filter UI despite correct server-side filtering; search terms remain out of the URL.
- Added Dashboard security posture, shared Password/MFA/Sessions navigation, contextual Audit empty states and defensive Sessions empty state.
- No database migration, Gemfile/lockfile change, route change, Vault crypto-service change, key-provider contract change, VaultItemVersion change or MfaSetting persistence change.
- Latest verification: Rails 124/1051 PASS; system 20/183 PASS; RuboCop 158 files/0 offenses; Brakeman 0 warnings; bundler-audit clean; crypto 36/70 PASS; security 5/12 PASS; accessibility 45/785 PASS.

## 0.1.4-dev — Development Line Opened

- Forked byte-for-byte from the sealed stable 0.1.3 source; stable 0.1.3 remains the live immutable baseline.
- Opens a semantic-version development line instead of continuing the FIX-series.
- Carries forward every 0.1.3 verification/recovery/release gate as the regression floor.
- Prioritizes manual-accessibility evidence closure, operator/deployment UX, and a provider-safe KEK evolution path without changing encrypted-record schema by default.
- No promotion is implied by this development marker; `current` remains stable 0.1.3 until a future release candidate is explicitly sealed and promoted.
- Adds a secret-safe `script/operator-status` surface for development/operator recovery checks while stable remains live.
- Adds a human accessibility evidence worksheet that deliberately remains PENDING/UNTESTED until reviewed by a person.
- Makes key rotation provider-neutral through `KeyProviders::Registry.fetch` and adds `verify_key!` to the provider base contract; LocalFile format/schema remain unchanged.
- Sets BCrypt minimum cost only inside the test process so recovery-code functional tests remain semantically equivalent without production-strength CPU cost.
- Updated 0.1.4-dev regression: Rails 111/980 PASS; system 15/132 PASS; RuboCop 149/0; Brakeman 0; audit clean; crypto 26/49 PASS; security 5/12 PASS; accessibility smoke 42/737 PASS.
- Adds a test-only in-memory key provider proving provider-neutral rotation through Registry.fetch, including wrong-key, wrong-context and tamper rejection without registering a production KMS provider.
- Adds a vendor-neutral ExternalKms adapter skeleton with capability, configuration/error, encryption-context and recovery/custody contracts; production registry intentionally remains closed to external_kms.

## 0.1.3 — Stable Release Consolidation

- Consolidates the accepted 0.1.2-FIX46 baseline and accepted 0.1.3-RC1 candidate into the stable 0.1.3 milestone.
- Adds FIX46-to-0.1.3 upgrade evidence with identical migration-set verification, idempotent production db:migrate, no pending migrations, persistent database reuse and project-doctor PASS.
- Preserves all production preflight gates from FIX40–FIX46: UX/accessibility automation, HTTP security, safe failures, logging redaction, CSRF/origin, rate limiting and session lifecycle.
- Updates the stale README release marker and adds a production-readiness matrix plus explicit upgrade/rollback guidance.
- Introduces no new database migration or envelope-encryption data-model change.

## 0.1.2-FIX16 - 2026-09-28

- Proven on a persistent AWS EC2 systemd host across a real reboot.
- Added production Puma/systemd + Caddy HTTPS deployment contract and acceptance scripts.
- Added deterministic production asset precompile/output ownership and asset/MIME acceptance.
- Added CSP nonce support for Turbo-injected styles without enabling unsafe-inline.
- Preserved CSRF authenticity-token enforcement while allowing browsers that send Origin: null.
- Added production-safe owner provisioning wrapper.
- Added Ubuntu 26.04 + PostgreSQL 17 live-host compatibility.
- Fixed test portability so database.yml does not require production DATABASE_URL while booting test.
- Added reusable web-stack doctor and CSRF-origin acceptance.
- Runtime CI on EC2: 49 tests / 189 assertions; 5 system tests / 54 assertions; RuboCop 120 files / 0 offenses; Brakeman 0 warnings; bundler-audit 0 vulnerabilities.

# Changelog

## v0.1.2-FIX14 — Cross-Host Portability Hardening

- Removed runtime-only .bundle/config from the release source and hardened migration packaging to exclude .bundle, preventing Kaggle-specific Bundler paths from leaking into Linux-host restores.
- Normalized all operational script entrypoints to executable mode 0755; the FIX14 restore helper re-applies executable modes after extraction.
- Changed the local DR PostgreSQL socket default from the Kaggle runtime path to /var/run/postgresql, while retaining DR_LOCAL_PG_SOCKET override support.
- Added script/portability-check and wired it into bin/ci; the gate rejects .bundle/config, hardcoded /kaggle/working deployment/runtime paths, non-executable operational scripts, and a non-portable DR socket default.
- Hardened script/verify-backup so pg_restore catalog incompatibility prints the installed pg_restore version and a clear recovery-tooling compatibility requirement. PostgreSQL 17 is known-good for the current FIX13/FIX14 acceptance backups.
- Added package-rev-migration-bundle-FIX14.sh with internal manifest verification plus bundle portability verification.
- Live E2B acceptance evidence carried forward from FIX13: clean-host restore, real rclone offsite download, PostgreSQL 17 fresh-database restore, Rails recovery-KEK decrypt, exact canary validation, and manual scheduled daily backup/offsite round-trip all passed.

## v0.1.2-FIX13 — Persistent Scheduler Host Deployment Kit

- Added `script/install-ops-scheduler` for guarded installation/staging of the release tree, protected operations environment, runtime directories, and either systemd units/timers or an `/etc/cron.d` entry.
- Live installation defaults to disabled timers; `OPS_INSTALL_ENABLE=1` is required to `systemctl enable --now` the daily and DR timers.
- Installer refuses dangerous root release prefixes, unsafe paths/user/group names, invalid enable values, and live installation without root privileges.
- Installer preserves an existing `ops.env` instead of overwriting secrets, forces mode 0600, and creates backup/state/evidence directories mode 0700; live installs assign them to the scheduler service account.
- Release copying explicitly excludes Git metadata, `.env*`, fix backups, runtime log/tmp/storage, and `*.key`/`*.pem`/`*.agekey` material.
- Expanded `ops/ops.env.example` with the complete scheduler contract: Rails/DB production context, KEK context, age backup/recovery, explicit `RCLONE_CONFIG`, real offsite destination, fake DR canary, state/evidence paths and optional alerts.
- Added `script/ops-scheduler-doctor` to validate the deployed runner, env contract/permissions, runtime directories, required binaries, systemd/cron definitions and timer syntax. On a live host it also rejects placeholders, verifies service account/group, key/config presence, and service-user read/write access.
- Runtime-proven systemd staging installation/doctor PASS, including calendar parsing and persistent timers.
- Runtime-proven cron staging installation/doctor PASS and preservation of a pre-existing environment file.
- Runtime-proven dangerous `OPS_INSTALL_PREFIX=/` rejection and exclusion of intentionally planted secret-like files from the staged release.
- Kaggle remains staging validation only; activation of a durable timer/cron daemon belongs on the persistent deployment host.
- Full Kaggle CI runtime evidence: Rails 49/189 PASS, system 5/54 PASS, RuboCop 119 files clean, Brakeman 0 warnings, bundler-audit 0 known vulnerabilities.

## v0.1.2-FIX12 — Scheduled Operations & Alerting

- Added `script/scheduled-ops` with non-blocking `flock` locking so overlapping scheduler invocations fail safely with exit 75 instead of running concurrent backup/DR jobs.
- Added `daily`, `dr`, and `all` execution modes. Daily mode runs encrypted backup → verification → configured real offsite round-trip → retention; DR mode selects the newest encrypted backup on the configured rclone remote and runs full offsite DR rehearsal.
- Added safe per-run JSON evidence with timestamps and stage statuses, plus a `last-dr-success` state marker.
- Added failure alert sinks: append-only JSONL file and optional JSON webhook. Alert payloads contain only schema/timestamp/status/mode/message metadata and no database URL, key path, canary value, age recipient/identity, or remote credentials.
- Runtime-proven lock contention: concurrent invocation exits 75 with no second job.
- Runtime-proven failure alert path: intentionally missing backup recipient produced non-zero scheduled run plus a minimal safe alert JSON record.
- Runtime-proven daily path with a newly created encrypted backup, checksum/catalog verification, real `ruby-vault-offsite:` rclone round-trip, retention dry-run and safe evidence JSON.
- Runtime-proven scheduled DR mode against the newest backup on the real remote; fresh database restore and exact canary validation completed successfully.
- Added `ops/ops.env.example`, cron examples, and systemd daily/weekly service+timer templates. Kaggle does not provide a durable cron daemon, so scheduler-daemon activation is intentionally left to a persistent deployment host.
- Added `script/scheduled-ops` to local and GitHub Actions shell-syntax gates.
- Full Kaggle CI runtime evidence: Rails 49/189 PASS, system 5/54 PASS, RuboCop 119 files clean, Brakeman 0 warnings, bundler-audit 0 known vulnerabilities.

## v0.1.2-FIX11 — Portable Offsite Disaster Recovery

- Fixed backup checksum sidecars to store the backup basename instead of an absolute source path.
- Hardened `script/verify-backup` to hash the exact file argument and compare its SHA-256 directly, so a relocated/offsite-restored artifact cannot accidentally validate an old source-path file referenced by a legacy sidecar.
- Preserved compatibility with existing sidecars by reading only the expected hash token, while refusing malformed non-SHA-256 sidecars.
- Added `script/offsite-dr-rehearsal` to download an encrypted backup and checksum from a real named rclone remote into a fresh staging directory, verify it, restore into a guarded fresh PostgreSQL database, decrypt the exact canary, and clean up both DB and staging by default.
- Normalized the existing offsite acceptance checksum sidecar on `ruby-vault-offsite:ruby-envelope-vault` to portable basename format.
- Runtime-proven negative regression: a corrupted staged artifact fails verification even when its legacy sidecar still contains the checksum of the valid original backup.
- Runtime-proven real offsite DR: remote download → checksum/catalog verify → fresh DB restore → exact canary decrypt → DR DB cleanup → staging cleanup all PASS.
- New backups were runtime-proven to emit portable basename checksum sidecars.
- Added the new offsite DR primitive to local and GitHub Actions shell-syntax gates.
- Full Kaggle CI runtime evidence: Rails 49/189 PASS, system 5/54 PASS, RuboCop 119 files clean, Brakeman 0 warnings, bundler-audit 0 known vulnerabilities.

## v0.1.2-FIX10 — External HTTPS / Real Offsite Acceptance

- Installed persistent runtime copies of `cloudflared` and `rclone` under the Kaggle runtime tools directory for deployment acceptance work.
- Created a real public Cloudflare Quick Tunnel and ran `script/production-smoke` through the external HTTPS endpoint; HSTS, CSP, nosniff, frame-deny, no-store, no-referrer and COOP checks all passed.
- Hardened strict rclone offsite acceptance: `REQUIRE_REAL_OFFSITE=1` now requires a named configured rclone remote and rejects `local`, `memory` and `alias` backend types.
- Strict production acceptance proved HTTPS, KEK technical recovery integrity and encrypted-backup verification PASS while failing closed on the missing real rclone remote.
- Cloudflare Quick Tunnel acceptance is external HTTPS evidence only; it is not claimed as a production hosting endpoint because Quick Tunnels provide no uptime guarantee.
- Runtime-proven with configured `ruby-vault-offsite:` rclone remote: encrypted backup upload → retrieve → SHA-256 verification PASS; strict production-acceptance command exited 0 with ops, HTTPS, KEK technical recovery integrity, backup verification and real rclone round-trip all PASS.
- Scope note: this release proves the software acceptance contract against an external HTTPS tunnel and real rclone remote; a durable production hostname/tunnel and physically or administratively independent KEK custody remain deployment-operations requirements before storing irreplaceable real secrets.

## v0.1.2-FIX9 — Production Deployment Acceptance Kit

- Added `script/offsite-roundtrip` with filesystem acceptance mode and production `rclone` mode; it uploads backup+checksum, retrieves both, and verifies the retrieved SHA-256.
- Added `script/kek-recovery-check` to enumerate KEKs still referenced by encrypted Vault/MFA records and verify separate recovery copies by size, permissions and fingerprint.
- Added `script/production-acceptance` to compose ops readiness, live HTTPS smoke, KEK recovery custody, backup verification and offsite round-trip checks with explicit strict-mode requirements.
- Strict real-offsite mode refuses the filesystem adapter and requires `OFFSITE_DRIVER=rclone`, preventing local acceptance from being mislabeled as real offsite proof.
- `script/ops-maintenance` now optionally performs offsite round-trip verification and records `offsite_roundtrip` in its safe JSON report.
- Kaggle validation is explicitly classified as semantic/local acceptance only; real Internet/TLS endpoint, real rclone remote and physically independent KEK custody remain deployment-specific gates.
- Full Kaggle CI runtime evidence: Rails 49/189 PASS, system 5/54 PASS, RuboCop 119 files clean, Brakeman 0 warnings, bundler-audit 0 known vulnerabilities.

## v0.1.2-FIX8 — Deployment Operations / Monitoring Contract

- Added `script/ops-report` for operator-only machine-readable JSON status while keeping public `/ready` minimal.
- JSON status exposes only safe check states, timestamp/duration and optional backup basename/SHA-256; credentials, KEK paths, age identity/recipient and canary plaintext are excluded.
- Added `script/ops-maintenance` for encrypted backup → checksum/catalog verification → optional guarded DR rehearsal → guarded retention → JSON report.
- Added `script/backup-retention`; it is dry-run by default, refuses `RETENTION_KEEP < 2`, manages only named vault backup patterns, and requires explicit `RETENTION_APPLY=1` for deletion.
- Hardened `script/dr-rehearsal` cleanup so a database-drop failure is fatal and prints FAIL rather than being hidden by `|| true`.
- Fixed Kaggle self-heal to persist `APP_HOSTS=localhost` in demo mode so the previously proven production-mode `script/ops-check` remains reproducible after reconnect.
- Runtime negative acceptance proved fail-closed behavior for corrupt checksum, wrong age identity, wrong canary, invalid DR prefix, database-create failure and cleanup failure.
- Local `bin/ci` and GitHub Actions now shell-validate the FIX8 operational scripts.
- Full Kaggle CI runtime evidence: Rails 49/189 PASS, system 5/54 PASS, RuboCop 119 files clean, Brakeman 0 warnings, bundler-audit 0 known vulnerabilities.

## v0.1.2-FIX7 — Guarded Disaster-Recovery Rehearsal

- Added `script/dr-rehearsal` to orchestrate backup verification, fresh-database creation, restore, exact canary decrypt and automatic cleanup in one command.
- The rehearsal target must use the `ruby_envelope_vault_dr_` prefix and is never allowed to equal the source database.
- Exact `EXPECTED_CANARY_FIELD` and `EXPECTED_CANARY_VALUE` are required so a successful decrypt alone cannot be mistaken for a full recovery proof.
- The application database role remains non-CREATEDB; local Kaggle rehearsals use the PostgreSQL OS account for create/drop, while non-local deployments can provide `DR_ADMIN_DATABASE_URL`.
- Added `KEEP_DR_DATABASE=1` only as an explicit opt-in for post-rehearsal inspection; default behavior cleans up the generated DR database.
- Runtime-proven with a new fake FIX7 canary, a freshly created age-encrypted PostgreSQL backup, checksum/catalog validation, restore into a generated fresh database, exact canary decrypt and automatic cleanup.
- Verified source-target guard fails closed and confirmed the exact FIX7 rehearsal database no longer existed after cleanup.
- Added `script/dr-rehearsal` and `script/ops-check` to GitHub Actions shell-syntax validation.
- Updated README, backup/restore guide and production checklist with the repeatable rehearsal path and current runtime-validation counts.
- Full Kaggle CI runtime evidence: Rails 49/189 PASS, system 5/54 PASS, RuboCop 119 files clean, Brakeman 0 warnings, bundler-audit 0 known vulnerabilities.

## v0.1.2-FIX6 — Operational Readiness Gate

- Added operator-only `script/ops-check` without exposing internal component details through the public readiness endpoint.
- Reused the existing production boot security initializer as the source of truth instead of duplicating production policy in shell.
- The operator gate validates required CLI tooling, Rails production boot checks, PostgreSQL connectivity and active Vault KEK verification.
- Added optional strict enforcement for encrypted-backup configuration through `OPS_REQUIRE_BACKUP_CONFIG=1`.
- Added optional strict enforcement for live HTTPS/security-header smoke through `OPS_REQUIRE_HTTPS_SMOKE=1` and `APP_URL`.
- Runtime-proven Kaggle behavior: local operator gate PASS with HTTPS/offsite checks explicitly SKIP; strict gate exits non-zero when `BACKUP_AGE_RECIPIENT` and `APP_URL` are absent.
- Added readiness request regression coverage proving healthy DB+KEK returns 200 and key-provider failure returns 503 with an empty response body and no leaked provider error details.
- Updated production and backup/DR documentation with normal and strict operator-gate commands.
- Full Kaggle CI runtime evidence: Rails 49/189 PASS, system 5/54 PASS, RuboCop 119 files clean, Brakeman 0 warnings, bundler-audit 0 known vulnerabilities.

## v0.1.2-FIX5 — UI/View Architecture + Search/Filtering Acceptance

- Refactored duplicated vault create/edit forms into a shared `app/views/vault_items/_form.html.erb` while preserving blank-password-on-edit semantics and secret-field protections.
- Added archive/unarchive controls, archived-state badges and browser/audit/IDOR acceptance.
- Added safe item metadata and an explicit empty-vault state without persisting decrypted titles.
- Added `Vault::ListItems`: metadata filtering, encrypted-title search performed only after in-memory decrypt for the current user, candidate cap, and pagination after search.
- Added POST-only encrypted-title search so sensitive title fragments do not enter the browser URL/history; added `q` to Rails parameter filtering.
- Added `Audit::ListEvents`: per-user exact-action filtering and pagination; fixed the UI transport parameter to `event_action` to avoid Rails' reserved `params[:action]`.
- Polished version history with a single current-version marker, clear timestamps, restore-as-new-version explanation and restore confirmation.
- Polished session management with current/active/revoked state badges and explicit revoke confirmations.
- Improved password-change form accessibility with labels, required/minlength constraints and help text while preserving existing session-rotation/revocation semantics.
- Improved MFA settings with accessible token labels, recovery-code invalidation warning and confirmation before disabling MFA.
- Full Kaggle CI runtime evidence: Rails 47/181 PASS, system 5/54 PASS, RuboCop 118 files clean, Brakeman 0 warnings, bundler-audit 0 known vulnerabilities.

## v0.1.2-FIX4 — Functional Acceptance + Restart Self-Heal

- Added browser acceptance for vault create/edit/version restore/reauth/reveal.
- Added browser acceptance for MFA TOTP login, one-time recovery-code login, MFA enrollment, recovery-code display, MFA disable and current-session revocation.
- Added service and request regression coverage proving recovery codes are single-use and accepted through the MFA challenge flow.
- Added environment `.env` export acceptance including no-store headers, attachment filename/body and audit event.
- Added IDOR acceptance for show, reveal, export, version index and version restore endpoints.
- Increased system-test wait only for browser tests after proving bcrypt recovery-code verification can exceed Capybara's default wait; production timeouts are unchanged.
- Hardened Kaggle restart self-heal for executable-bit drift across Rails scripts, mise Ruby binaries, Selenium/Chrome cache and Bundler gem `bin/`/`exe/` trees.
- Hardened PostgreSQL restart recovery: reinstall the PG major required by persisted `PG_VERSION`, repair PGDATA ownership/mode, and recreate standard empty PostgreSQL runtime directories lost by notebook persistence.
- Avoid replacing Kaggle's existing `pkgconf` provider with `pkg-config`, preventing unrelated `r-base-dev` removal; host package state was restored during runtime validation.
- Runtime-proven bootstrap self-heal after device switch: PostgreSQL 17.11, Redis 6.0.16, Tailwind native binary, database/Redis connections and KEK all recovered successfully.
- Full CI runtime evidence: Rails 42/160 PASS, system tests 5/33 PASS, RuboCop 114 files clean, Brakeman 0 warnings, bundler-audit 0 known vulnerabilities.

## v0.1.2-FIX3 — Runtime Acceptance Completion

- Restored the intended `rubocop-rails-omakase` configuration via `.rubocop.yml`; RuboCop now passes cleanly.
- Applied only safe RuboCop autocorrections and re-ran the full Rails suite with no regressions.
- Added Capybara + Selenium WebDriver system-test infrastructure and a real unauthenticated-login browser smoke test.
- Added Chrome-for-Testing runtime libraries to the Kaggle bootstrap and persistent Selenium cache under project `tmp/`.
- Added system tests to `bin/ci`, GitHub CI and bootstrap validation.
- Fixed `bin/ci` so the restricted `vault_user` no longer needs CREATEDB privileges.
- Runtime-proven plaintext canary absence in `pg_dump`.
- Runtime-proven age-encrypted DB backup, checksum/catalog verification, fresh-DB restore and decrypt.
- Strengthened `script/dr-verify` with optional exact canary field/value validation; mismatch now fails closed.

## v0.1.2-FIX2 — Kaggle Runtime Acceptance Fixes

- Fixed normalized-account Rack::Attack throttling to use canonical request parameters.
- Isolated Rack::Attack cache and Current state between integration tests.
- Full Rails suite runtime-proven on Kaggle: 36 runs, 113 assertions, 0 failures, 0 errors.
- Targeted request regression tests: 5 runs, 27 assertions, 0 failures, 0 errors.
- Zeitwerk eager-load check PASS after FIX1 crypto error-class file split.
- Kaggle doctor PASS for Ruby, Bundler, PostgreSQL, Redis, database connectivity and KEK checks.
- Brakeman: 0 security warnings. Bundler Audit: no vulnerabilities found.
- Key rotation test: 2 runs, 13 assertions, 0 failures, 0 errors.
- Rails development server boot and /up HTTP 200 verified on Kaggle.
- Known pending gates: RuboCop cleanup, browser/system tests, plaintext canary proof, full DR restore+decrypt.

# v0.1.2 — Kaggle / Dockerless Bootstrap

- Added root `bootstrap.sh`: one-command Docker-free setup for Kaggle Notebook terminals.
- Installs OS build dependencies, PostgreSQL, Redis, `age`, mise and Ruby 3.4.11.
- Keeps mise/Ruby gems/private PostgreSQL cluster/Redis runtime/KEKs under `/kaggle/working/.ruby-envelope-vault-runtime` by default.
- Starts PostgreSQL through `pg_ctl` and Redis through a private config/pidfile; no systemd is required.
- Idempotently creates SCRAM-protected application role plus development/test databases.
- Generates `.env.kaggle` with mode `0600` and preserves generated DB/Redis/application secrets across reruns.
- Generates `activate-kaggle.sh` for new terminals.
- Runs crypto/security self-tests, Rails DB preparation, Tailwind build, key verification and optionally the full Rails test suite.
- Supports optional interactive/non-interactive owner creation.
- Added `setup/start/stop/status/doctor` subcommands to the same bootstrap file.
- Extended project doctor with PostgreSQL and Redis connectivity checks.
- Kaggle runtime remains explicitly classified as development/demo, not an irreplaceable secret store.


## 0.1.1 — 2026-09-27

Production-security hardening release built from the v0.1.0 crypto foundation.

### Added
- server-side session idle timeout, absolute timeout, revocation, and activity tracking;
- non-permanent signed session identifier cookie with Strict SameSite and session-ID rotation across sensitive authentication boundaries;
- recent reauthentication requirement for sensitive operations;
- TOTP MFA with the full RFC 6238 SHA-1 test vectors, encrypted server-side enrollment state, short setup expiry, and replay prevention;
- one-time MFA recovery codes stored only as bcrypt hashes with locked single-use consumption;
- encrypted TOTP seed stored through the same envelope-encryption engine;
- stronger Rack::Attack throttles by IP, normalized account hash, and hashed session-cookie discriminator;
- production fail-fast environment/KEK checks including mandatory MFA + reveal reauthentication outside demo mode;
- Host Authorization allowlist through `APP_HOSTS`/`APP_HOST`;
- stricter CSP without `unsafe-inline` styles;
- additional browser security headers;
- immutable encrypted item version creation and version restore;
- `.env` parser plus streamed `.env` export with no-store responses;
- audit log UI and session-revocation UI;
- local-file KEK rewrap rotation task with dry-run and verification;
- Docker healthcheck and Kamal deployment configuration;
- `Gemfile.lock`, patched `resolv >= 0.7.2`, Dependabot and expanded CI jobs;
- production security checklist and DR restore+decrypt helper;
- audit-metadata sensitive-key guard and request-id correlation;
- browser/Turbo plaintext scrubbing and non-prefilled password editing;
- encrypted backups by default, with explicit opt-in required for plaintext dumps.

### Security defaults
- password minimum increased to 14 characters;
- personal production expects `ALLOW_SIGNUPS=false`, `REQUIRE_MFA=true`, `FORCE_SSL=true`;
- secret/cipher fields and OTP/recovery-code parameters are filtered from logs.

### Validation limitation
The build environment used to assemble this archive has Ruby 3.3.8 and no network access, so full Rails 8.1.4 bundle installation/PostgreSQL integration could not be executed here. Standalone crypto/TOTP/.env tests and static syntax/YAML checks were executed. Run `bin/ci` on Ruby 3.4.11 with PostgreSQL before production use.
