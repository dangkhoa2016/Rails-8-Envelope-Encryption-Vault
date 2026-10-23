# Kaggle / Google Colab Full Demo — Ruby Envelope Vault v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](KAGGLE-SETUP.vi.md)

## Run the complete Rails application from GitHub

**[Open the bilingual Kaggle / Colab notebook](../notebooks/Ruby_Envelope_Vault_v1_Kaggle_Colab_Full_Demo.ipynb)**

**Which source revision?** This page's primary notebook runs the unchanged annotated `v1.0.0` release tag (`b8e7828`). To reproduce subsequent Audit and Vault UX improvements from `main`, use the separate **[verified main-snapshot demo](../notebooks/Ruby_Envelope_Vault_Main_Kaggle_Colab_Full_Demo.ipynb)**, pinned to `52314b474b6a0daa389eeca5ed49a386fe33e8a3` (SHA and Git tree both verified). This post-tag notebook preserves the same bootstrap, complete test suites, synthetic fixtures and optional browser showcase, but checks a commit rather than an annotated release tag. It does not relabel new behavior as part of `v1.0.0`.

This is a CPU-only, Docker-free demonstration that starts with the actual tagged repository source—not a separate Kaggle Dataset, prepared database dump, container image or hosted production service.

The notebook provisions Ruby 3.4.11, Rails 8.1.4, PostgreSQL 17, Redis, a disposable LocalFile KEK and database schema. It runs cryptographic/security checks, the entire Rails and Selenium test suites, seven categories of encrypted synthetic vault items, HTTP health checks and optionally ten real UI screenshots plus a verified showcase archive.

## Requirements

- Kaggle notebook (CPU, **Internet enabled**) or Google Colab notebook (CPU, Internet access). Ubuntu/Debian packages and permission to install them are required.
- Writable runtime storage with several gigabytes available; Chrome/Selenium runs on CPU.
- **GitHub access:** The repository is currently **Private**. You must have permission to read it. Create a fine-grained GitHub token limited to this one repository with only **Contents: Read** and store it as `GH_READ_TOKEN` in Kaggle Secrets or Colab Secrets. An account without repository permission cannot clone it merely by creating a token.
- When the repository becomes Public, the notebook tries anonymous cloning first: **no GitHub token is needed**.
- A temporary **public Cloudflare Quick Tunnel is enabled by default** (Rails authentication still applies). No Cloudflare email OTP is needed. The temporary URL can be opened by anyone who knows it; only use synthetic data and keep the generated demo password private. Explicitly disable the tunnel for localhost-only tests.

## Start in Kaggle or Colab

1. Open the [notebook file](../notebooks/Ruby_Envelope_Vault_v1_Kaggle_Colab_Full_Demo.ipynb) on GitHub. Download it and import the `.ipynb` into **Kaggle Code** or **Google Colab**.
2. On Kaggle select **CPU** and enable **Internet**. If cloning this Private repository, set up the secret `GH_READ_TOKEN` (read-only) before running.
3. Leave `ENABLE_CLOUDFLARE_TUNNEL = True` to open a browser URL automatically **after** Rails passes `/up=200` and `/session/new=200`. No email or OTP prompt is required. Set the flag to `False` for localhost-only testing. Keep screenshot capture and showcase packaging enabled for the full demo.
4. Choose **Run All** and review the output after each major stage. The notebook validates the annotated `v1.0.0` tag, checks that it resolves to the checked-out commit, verifies the fetched Git objects with `git fsck`, then checks the application version and clean working tree. No source-file SHA values are hard-coded.
5. When the notebook prints `CLOUDFLARE_TUNNEL=READY`, click `BROWSER_DEMO_URL` to open the Rails login page. Log in with the synthetic `showcase@example.test` account and the randomly generated demo password from **private** notebook output; do not share the password.
6. Browse the dashboard, Vault categories, item details, immutable versions, audit trail, MFA/security and session screens. The screenshot step generates ten real desktop/mobile Selenium screenshots using synthetic data. The showcase package contains checksum manifests and an integrity report.
7. End the session with the optional shutdown cell. Clear notebook output before sharing. Do **not** upload runtime logs, actual credentials, the demo password, KEK files or database dumps to GitHub.

**Current demo fixture profile (v1.0.0):** the demo seed creates **28 encrypted synthetic items**, four examples in each of the seven categories, with **29 encrypted versions** and **29 creation/update audit events** on a clean demo account. The Vault index displays **6 items per page**, allowing five pages of browsing, Previous/Next controls and category/tag filtering. Re-running the fixture without `DEMO_RESET` adds only missing examples; for existing six-item accounts, re-run the fixture to add the 22 new records. The acceptance table below records the **historical 2026-10-22 run**, before this fixture expansion, and is intentionally unchanged.

**Release versus later UX behavior:** The original `v1.0.0` tag searches Vault titles by POST → HTTP 303 → GET. GET pagination preserves filters from the encrypted session, with no plaintext title in the URL. The later pinned `main` snapshot uses Turbo Stream to update results without full-page reload; it sets a GET URL with a random, session-scoped `filter` reference and optional safe `kind`, `status`, `favorite` fields, keeping decrypted title and tag names out of the URL. Audit Category immediately refreshes available Action choices in the **later snapshot**, whereas this interaction is not part of the earlier tag. Never infer the later behavior from the tag alone.

**Git trust boundary:** These checks verify checkout/object consistency, not release authenticity. A movable unsigned tag can be replaced; independent authenticity requires a trusted signed release tag or equivalent external trust anchor.

**Re-running the notebook:** Each full Run All creates a fresh isolated Git checkout to avoid stale or dirty working directories. Prior checkout directories are preserved until runtime reset, which may use additional disk space. After seeding, the notebook expects at least four items in each of seven categories and at least 29 encrypted versions; it no longer checks for the obsolete six-item demo.

**Repeated Run All and database authentication:** Every run creates its own PostgreSQL role, development/test databases, and available Rails HTTP port. Older servers cannot satisfy the new run's health check and existing database roles are not re-passworded. Before publishing the Cloudflare browser URL, the notebook checks an authenticated PostgreSQL SELECT 1, not just HTTP /up. These are disposable synthetic demo databases; reset the notebook runtime to reclaim storage and retire old processes.

## Verified acceptance and runtime boundaries

The *separate, manually executed* Kaggle CPU acceptance run on 2026-10-22 achieved:

| Verification | Observed result |
| --- | --- |
| Rails unit/integration | 216 tests / 2,127 assertions / 0 failures |
| Selenium system | 21 tests / 223 assertions / 0 failures |
| Synthetic encrypted fixtures | 6 items / 7 versions / 7 audit events |
| Local HTTP | `/up` and `/session/new`: 200 |
| Selenium screenshots | 10/10 PASS |
| Showcase integrity | 307 links/references checked, 10 screenshots, 59 root files — PASS |

**Evidence boundary:** The earlier Kaggle acceptance and a user-supplied Colab Run All confirmed the local Rails pipeline. The simplified Rails-first Quick Tunnel workflow now passes source checks but **still requires a fresh Colab browser smoke test**. Do not report interactive external-browser acceptance until a tester opens the URL and logs in.

### Test-only umask compatibility

The tagged v1.0.0 source has a test that assumes a directory created with `Dir.mkdir(path, 0o755)` will have mode `0755`; the bootstrap intentionally uses `umask=077`, resulting in `0700` and one failing permission assertion. This is an environment-sensitive **test** issue, not an envelope-encryption failure.

The notebook installs services with `START_SERVER=0 RUN_TESTS=0`, **still runs crypto/security self-tests and project doctor**, and then separately runs **all** Rails and Selenium suites with test-only `umask=022`. The KEK and protected environment remain at `0600`. A future code/test fix should make the permission test independent of the ambient umask.

## Safety and troubleshooting

Only use synthetic fixtures in ephemeral notebook environments. Cloudflare Quick Tunnels are temporary development access, **not** an accepted production deployment. Keep the protected logs and generated files outside Git; on failure inspect the phase-specific logs privately and never paste tokens, passwords or secret-key material into issues. For more context see the [security policy](SECURITY.md), [reproducibility guide](reproducibility.md), [troubleshooting](troubleshooting.md) and [Qualification matrix](qualification.md).

The source release stays at annotated tag `v1.0.0`; this notebook is a separately committed reproducible demo wrapper, not a replacement for the tagged application code.
