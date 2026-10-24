# Rails 8 Envelope Encryption Vault — Kaggle / Google Colab Interactive Demo

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](KAGGLE-SETUP.vi.md)

## Explore the actual Rails application

**[Open the bilingual interactive notebook](../notebooks/Rails_8_Envelope_Encryption_Vault_Kaggle_Colab_Demo.ipynb)**

This is the project's **single supported Kaggle / Colab notebook**. It starts a real Rails 8 encrypted Vault with **28 synthetic sample items** across seven categories, a Dashboard, Search, pagination, Favorites, Archive, immutable history, and Security Activity filters. No GPU is needed. Source code comes from GitHub, not a Kaggle Dataset.

The notebook provides **two experiences** in one file:

| Experience | Intended for | What runs |
| --- | --- | --- |
| **Explore** (default) | First-time users | Source integrity verification, bootstrap crypto/security preflight, sample data, a running Rails site and encrypted-envelope metadata checks |
| **Verify** | Technical reviewers | Everything in Explore, **plus** complete Rails/Selenium test suites, ten real desktop/mobile screenshots (by default), screenshot checksum verification and a sanitized evidence package |

Full Rails/Selenium tests are retained in Verify, **after the site becomes accessible**. A failing optional browser capture should not prevent someone from trying the product.

## Run the demo

1. Import the [canonical notebook](../notebooks/Rails_8_Envelope_Encryption_Vault_Kaggle_Colab_Demo.ipynb) into a **Kaggle CPU** notebook (Internet enabled) or **Google Colab CPU**. Use a Linux runtime with installation permissions and several gigabytes of free disk space.
2. Set **DEMO_EXPERIENCE = "explore"** (default), or **"verify"** for the full test and evidence workflow. Keep **ENABLE_CLOUDFLARE_TUNNEL = True** only if you accept a *publicly reachable temporary login page*. Set False for local-only access.
3. The notebook clones the reviewed source anonymously from the official GitHub repository. No GitHub access token or Kaggle/Colab Secret is required. Never paste credentials into code cells or Git URLs.
4. Run **Run All**. The first steps install dependencies, verify source integrity, prepare an isolated demo database and generate a disposable account. The browser cell displays **Open Rails 8 Envelope Encryption Vault** after Rails and PostgreSQL readiness checks.
5. Open the URL and sign in as **showcase@example.test**, using the **private random password printed in Step 4**. Try Search, pagination, Favorites, Archive, immutable versions and Security Activity.
6. In Verify, inspect the full Rails/Selenium results and optional screenshot gallery and artifact. Use the **Stop Rails 8 Envelope Encryption Vault** button in the last cell when finished; Run All does **not** stop the app automatically. If widget buttons are unavailable, set **STOP_DEMO_NOW = True** and run the last cell alone.

**Important:** Cloudflare Quick Tunnel has no email/OTP gate. Rails authentication is mandatory but **anyone with the tunnel URL can reach the login page**. Use only disposable synthetic fixtures, keep passwords and encryption keys private, and clear executed notebook outputs before sharing. The tunnel binary is pinned to the official Cloudflare release **2026.10.3** (linux-amd64) and verified with its published SHA-256 before execution.

## Technical verification and reproducibility

The notebook clones the official GitHub **main** history and checks out the **annotated `v1.0.0` release source itself**, not an older application snapshot. It checks that the release belongs to the main history, validates Git object integrity (`git fsck`), verifies `VERSION` and a clean detached checkout, then prints the exact release commit and Git tree SHA for reproducibility. When `main` contains subsequent work, the notebook intentionally continues to run the explicitly selected `v1.0.0` release, not unreleased code. A Git tag alone is not a signed publisher attestation; never use real credentials in this demo.

Every Run All creates a new source checkout, PostgreSQL role/database, HTTP port and private evidence directory. The demo password is **new per run** and saved outside Git with file mode **0600**. Basic crypto/security bootstrap checks run in both experiences. Explore additionally examines persisted synthetic envelope metadata without printing plaintext. Verify runs all Rails and Selenium suites with **test-only umask 022**; protected key/log permissions remain strict.

The screenshot workflow captures **ten real pages**, with a manifest and SHA-256 checksums. Evidence packaging is available in Verify. Screenshots and packages are **not** created by default in Explore. Avoid publishing notebooks with execution history, confidential logs, KEKs, credentials or database dumps.

## Evidence boundaries and help

Git SHA and tree checks establish content consistency, **not independent publisher authenticity or a security certification**. Synthetic local tests and GitHub CI do not prove operational KMS recovery, external key custody or production readiness.

See [security](SECURITY.md), [qualification](qualification.md), [reproducibility](reproducibility.md), [troubleshooting](troubleshooting.md) and the [production checklist](PRODUCTION-CHECKLIST.md). Verify the current [CI runs](https://github.com/dangkhoa2016/Rails-8-Envelope-Encryption-Vault/actions/workflows/ci.yml) against the exact release commit.
