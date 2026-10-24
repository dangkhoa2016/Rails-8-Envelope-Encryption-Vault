# Kaggle / Google Colab Full Demo — Ruby Envelope Vault

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](KAGGLE-SETUP.vi.md)

## One notebook, one reviewed application revision

**[Open the complete bilingual Kaggle / Colab notebook](../notebooks/Ruby_Envelope_Vault_Kaggle_Colab_Full_Demo.ipynb)**

This is the repository's **single supported demo notebook**. It clones the GitHub `main` history, detaches to the reviewed application commit `d0ffc2a15def747ca1b6b4e3a14cbab301663fc3`, and verifies its exact Git tree `8fb2e8074714249d71d397949ab0a23c8d2807ba`. All steps use source code from GitHub, not a Kaggle Dataset or prepared database.

The notebook demonstrates reactive Audit filtering, stateful Vault search without plaintext titles/tags in URLs, in-place Favorite actions, shared toast notifications, encrypted synthetic items and immutable versions. It installs Ruby 3.4, Rails 8, PostgreSQL 17 and Redis, runs cryptographic/security preflights, the complete Rails and Selenium suites, HTTP checks, optional browser screenshots, and optional showcase packaging.

**Release provenance:** The `v1.0.0` tag identifies the first community release and includes the reviewed application UX. The notebook pins the exact application commit immediately before final bilingual documentation, an ancestor of the tagged release. Commit and Git tree checks verify content consistency, not independent source authenticity.

## Requirements and security

- Kaggle CPU notebook with Internet enabled, or Google Colab CPU with Internet. Linux/Ubuntu or Debian environment; package installation rights and several gigabytes of writable space.
- On a **public** repository, anonymous Git clone requires no token. For a **private** repository or mirror, the runner must be authorized to read it; supply a fine-grained `GH_READ_TOKEN` with repository **Contents: Read** in Colab/Kaggle secrets. A token never grants access beyond its owner's permission. Never paste the token into notebook code or output.
- The optional **Cloudflare Quick Tunnel** exposes a temporary development URL. Rails login is still required, but anyone with the URL can reach the login page. Use only synthetic data, keep the generated demo password private, and disable `ENABLE_CLOUDFLARE_TUNNEL` if remote browser access is unnecessary.
- Notebook output, credentials, KEK material, SQLite/PostgreSQL dumps, logs, and screenshots containing secrets must not be committed or published.

## Run All

1. Open the [canonical notebook](../notebooks/Ruby_Envelope_Vault_Kaggle_Colab_Full_Demo.ipynb) and import it into Kaggle Code or Google Colab. Choose **CPU** and enable Internet.
2. If the repository is private, provide the **read-only** `GH_READ_TOKEN` secret. Otherwise use anonymous cloning; keep credentials out of notebook cells.
3. Keep `ENABLE_CLOUDFLARE_TUNNEL = True` for a browser demo or set it to `False` for localhost-only tests.
4. Run **all cells in order**. Verify `SOURCE_VERIFIED=PASS`, `SOURCE_TREE_VERIFIED=PASS`, complete Rails/Selenium test results and authenticated database readiness. The notebook checks Git objects and refuses a mismatched pinned source.
5. After `CLOUDFLARE_TUNNEL=READY`, open `BROWSER_DEMO_URL`, use the disposable synthetic demo credentials from **private** output, and test Dashboard, Vault search, Favorite, versions, Audit, MFA and Settings.
6. Optionally review the Selenium screenshots and checksum-protected showcase. At the end, stop services/reset the runtime and clear notebook outputs before sharing.

## User interface and synthetic fixtures

The demo fixture generator seeds **28 encrypted synthetic Vault items**, four in each of seven categories, creating at least **29 immutable versions** and associated audit events in a clean demo. Vault pagination defaults to six items per page; the notebook checks seven categories and protected source behavior.

The current reviewed application updates Vault search results using Turbo Stream, uses an opaque session-scoped `filter` token instead of decrypted search terms in URLs, and reactively updates Audit Action when Category changes. Favorite/Unfavorite on item details updates the button in place and posts a shared toast without redirecting to the listing.

## Verification and evidence boundaries

A pre-publication GitHub CI run of the matching UX source (2026-10-24) recorded **226 Rails tests / 2,303 assertions** and **28 Selenium tests / 346 assertions**, with zero failures, errors or skips. That evidence is revision-specific; the rewritten release commit requires its own passing CI before updating the release tag.

Historical Kaggle CPU acceptance on 2026-10-22 measured 216 Rails tests / 2,127 assertions, 21 Selenium tests / 223 assertions, six original synthetic items and 10/10 screenshots. It was a separate historical run, **not** a substitute for testing the current revision. A user subsequently accepted the full Global Toast UX Colab demo; an independent production-host audit is still not claimed.

### Test-only umask

The bootstrap intentionally guards private files using `umask=077`. Some permission assertions require `umask=022` during the **test phase only**. The notebook keeps KEK and protected environment permissions at `0600` and does not skip Rails/Selenium suites. Directory-mode assertions depend on the test-phase umask; no tests are skipped and production secret permissions remain strict.

### Runtime isolation and security limits

Each Run All uses a fresh checkout and independent database role/name and Rails HTTP port to prevent stale process confusion. The notebook checks authenticated database access before publishing a temporary tunnel URL; prior runtime artifacts consume disk space until reset.

Git SHA and tree validation show checkout integrity, **not** independent source authenticity or production acceptance. For operational requirements see the [security policy](SECURITY.md), [qualification matrix](qualification.md), [reproducibility](reproducibility.md), [troubleshooting](troubleshooting.md), and [production checklist](PRODUCTION-CHECKLIST.md).
