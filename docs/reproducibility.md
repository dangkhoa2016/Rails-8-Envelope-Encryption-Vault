# Reproducibility and independent verification — v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](reproducibility.vi.md)

## Objective

A reproducible result identifies the **source revision**, **runtime**, **environment**, **commands**, and **actual outputs**. A passing test on another revision cannot be attributed to the reviewed commit. Do not infer live deployment approval from tests run with synthetic credentials.

## Baseline

| Dependency | Reference |
| --- | --- |
| Source revision | `git rev-parse HEAD` and annotated `v1.0.0` tag |
| Ruby | `.ruby-version` (3.4.11) |
| Rails | Pinned in `Gemfile.lock`; Rails 8.1.4 in `Gemfile` |
| PostgreSQL | 17 in CI |
| Local KEK | Synthetic 32-byte key; isolated test-only key directory |
| Test storage | Test database, never personal/production data |
| Browser/system tests | Selenium/Capybara dependencies as defined in CI |

## Route A — reproduce in GitHub Actions

1. Inspect [CI](../.github/workflows/ci.yml) and [documentation checks](../.github/workflows/docs.yml).
2. Match each run to the commit SHA under review; a branch badge alone is not an immutable proof.
3. Verify that Rails, lint, security, compatibility and Docker jobs correspond to the requested revision.
4. Record failed/retried jobs, environmental limitations and links to full logs.
5. Re-run the workflows after changing docs, code, CI or history.

## Route B — local development verification

Start from a clean checkout. Configure a disposable PostgreSQL test database and **synthetic** KEK material. Never source a production environment file to run the test suite.

```bash
git clone https://github.com/dangkhoa201/Rails-8-Envelope-Encryption-Vault.git
cd Rails-8-Envelope-Encryption-Vault
git checkout v1.0.0
git rev-parse HEAD
ruby --version
bundle install
```

Provide a test-only `TEST_DATABASE_URL`, and a locally generated KEK under a private directory. In CI, `VAULT_KEY_PROVIDER=local_file`, `VAULT_ACTIVE_KEK_ID` and `VAULT_KEK_DIR` are explicitly configured. For deterministic reproduction, use the same pattern instead of pointing at a personal key store.

```bash
export RAILS_ENV=test
# Export TEST_DATABASE_URL and synthetic VAULT_* values first.
script/crypto-self-test
script/security-self-test
bin/rails zeitwerk:check
bin/rails db:prepare
bin/rails test
bin/rails test:system
python3 script/doc-quality-check
script/repository-policy
```

To check lint/security with the locked gems:

```bash
bundle exec rubocop
bundle exec brakeman --no-pager -q
bundle exec bundle-audit check --update
```

These commands require the appropriate host tools and a test database. Refer to the CI YAML as the executable specification. If setup is unavailable locally, report **NOT RUN**, not PASS.

## Route C — ephemeral notebook demonstration

[Kaggle/Colab setup](KAGGLE-SETUP.md) provides the supported Docker-free bootstrap. A safe non-serving first invocation is:

```bash
START_SERVER=0 ./bootstrap.sh
./bootstrap.sh doctor
```

Bootstrap provisions isolated runtime state outside Git, but notebook storage and sessions may disappear. This path demonstrates application behavior; it does not validate persistent infrastructure, offsite backups, or custody of production keys.

## Evidence log template

```text
Source tag / SHA:
Environment / Ruby / PostgreSQL:
Key provider (name and synthetic key ID only):
Commands invoked:
Result per command (PASS, FAIL, NOT RUN):
CI run link / log path:
Known deviations and pending host acceptance:
```

**Never paste KEKs, tokens, user secrets, database dumps or private recovery identities into evidence reports.** Evidence should contain command names, exit states, checksums of appropriate public artifacts and scrubbed logs.

## What cannot be concluded

A local or CI PASS does not by itself establish offsite restore success, secure production TLS, isolated KEK recovery, privacy of application metadata, manual accessibility conformance or external cryptographic audit.

Continue with the [Qualification matrix](qualification.md), [Evidence index](evidence-index.md) and [Qualification matrix](qualification.md).
