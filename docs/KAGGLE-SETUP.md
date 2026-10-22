# Kaggle / Google Colab Full Demo — Ruby Envelope Vault v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](KAGGLE-SETUP.vi.md)

## Run the complete Rails application from GitHub

**[Open the bilingual Kaggle / Colab notebook](../notebooks/Ruby_Envelope_Vault_v1_Kaggle_Colab_Full_Demo.ipynb)**

This is a CPU-only, Docker-free demonstration that starts with the actual tagged repository source—not a separate Kaggle Dataset, prepared database dump, container image or hosted production service.

The notebook provisions Ruby 3.4.11, Rails 8.1.4, PostgreSQL 17, Redis, a disposable LocalFile KEK and database schema. It runs cryptographic/security checks, the entire Rails and Selenium test suites, six categories of encrypted synthetic vault items, HTTP health checks and optionally ten real UI screenshots plus a verified showcase archive.

## Requirements

- Kaggle notebook (CPU, **Internet enabled**) or Google Colab notebook (CPU, Internet access). Ubuntu/Debian packages and permission to install them are required.
- Writable runtime storage with several gigabytes available; Chrome/Selenium runs on CPU.
- **GitHub access:** The repository is currently **Private**. You must have permission to read it. Create a fine-grained GitHub token limited to this one repository with only **Contents: Read** and store it as `GH_READ_TOKEN` in Kaggle Secrets or Colab Secrets. An account without repository permission cannot clone it merely by creating a token.
- When the repository becomes Public, the notebook tries anonymous cloning first: **no GitHub token is needed**.
- Optional: an email address you control, for a temporary Cloudflare tunnel protected by One-Time PIN. No open tunnel is created by default.

## Start in Kaggle or Colab

1. Open the [notebook file](../notebooks/Ruby_Envelope_Vault_v1_Kaggle_Colab_Full_Demo.ipynb) on GitHub. Download it and import the `.ipynb` into **Kaggle Code** or **Google Colab**.
2. On Kaggle select **CPU** and enable **Internet**. If cloning this Private repository, set up the secret `GH_READ_TOKEN` (read-only) before running.
3. In the notebook settings cell, optionally set `ACCESS_EMAIL = "your-email@example.com"` for browser access using an OTP-protected Quick Tunnel; keep it empty if only local access is required. Leave `CAPTURE_SCREENSHOTS = True` and `MAKE_SHOWCASE_PACKAGE = True` for full verification.
4. Choose **Run All** and review the output after each major stage. The notebook verifies that the checkout matches the annotated `v1.0.0` tag, then checks Git blob fingerprints for the bootstrap, dependency lockfile and service provisioner.
5. For an email-gated tunnel, confirm the One-Time PIN sent to the selected address. Then sign in to Rails using the notebook-generated `showcase@example.test` account and temporary demo password shown in your **private notebook output**.
6. Browse the dashboard, Vault categories, item details, immutable versions, audit trail, MFA/security and session screens. The screenshot step generates ten real desktop/mobile Selenium screenshots using synthetic data. The showcase package contains checksum manifests and an integrity report.
7. End the session with the optional shutdown cell. Clear notebook output before sharing. Do **not** upload runtime logs, actual credentials, the demo password, KEK files or database dumps to GitHub.

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

**Scope warning:** This was a source-backed fresh Kaggle installation and manual sequence validation, **not** a separate, independently recorded `Run All` of this exact notebook file in a new session. Do not claim that notebook reproducibility is fully accepted until that run is completed.

### Test-only umask compatibility

The tagged v1.0.0 source has a test that assumes a directory created with `Dir.mkdir(path, 0o755)` will have mode `0755`; the bootstrap intentionally uses `umask=077`, resulting in `0700` and one failing permission assertion. This is an environment-sensitive **test** issue, not an envelope-encryption failure.

The notebook installs services with `START_SERVER=0 RUN_TESTS=0`, **still runs crypto/security self-tests and project doctor**, and then separately runs **all** Rails and Selenium suites with test-only `umask=022`. The KEK and protected environment remain at `0600`. A future code/test fix should make the permission test independent of the ambient umask.

## Safety and troubleshooting

Only use synthetic fixtures in ephemeral notebook environments. Cloudflare Quick Tunnels are temporary development access, **not** an accepted production deployment. Keep the protected logs and generated files outside Git; on failure inspect the phase-specific logs privately and never paste tokens, passwords or secret-key material into issues. For more context see the [security policy](SECURITY.md), [reproducibility guide](reproducibility.md), [troubleshooting](troubleshooting.md) and [Qualification matrix](qualification.md).

The source release stays at annotated tag `v1.0.0`; this notebook is a separately committed reproducible demo wrapper, not a replacement for the tagged application code.
