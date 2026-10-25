# Public-release security review — source-only preflight

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](PUBLIC-RELEASE-SECURITY-REVIEW.vi.md)

## Scope and evidence

This review was performed on an isolated checkout of the v1.0.0 source and the candidate search/documentation changes before changing repository visibility. The reviewer inspected the main encryption paths, key providers, authentication, user-scoped Vault access, session and MFA handling, audit details, GitHub workflows, runtime configuration and publication documentation.

A full-history text/pattern preflight was run **after fetching complete repository history**: 82 reachable commits, approximately 1,549,009 bytes of textual Git patch history. No tracked sensitive-file path or added patch line matching a known-format PEM private key, GitHub token, AWS access-key ID, Hugging Face token or Slack token pattern was detected. No secret value was printed. These are **heuristic negative results**, not proof that Git history contains no credentials. Rewritten/unreachable objects, platform artifacts, historical caches, environment files, live deployments, and third-party histories were not proven clean.

## Important boundaries and outstanding requirements

- Encryption is **server-side**, not zero-knowledge. A compromised Rails host authorized to call KeyProvider can potentially decrypt user content.
- AWS KMS production permissions, isolation and ciphertext costs/latency have **not** been independently tested in this review; CI exercises a synthetic LocalFile KEK.
- Vault Search now avoids a 250-row false-negative and decrypts only paged items for unfiltered listing. Searching private title/tag remains an O(N) decrypt operation and requires capacity limits/monitoring for larger deployments.
- Audit events are read-only in the application but are not cryptographically tamper-evident database records.
- Real offsite backup restore, separated KEK recovery, production HTTPS, private environment/credentials audits, retention/privacy expectations, and external security assessment are **not** certified by CI.
- Confirm that README sample credentials, screenshots, workflow logs and release notes include no private identifiers before publishing. Do not share live keys, authenticated session cookies, private runtime files or backups.
- Keep the repository **Private** until a distinct, documented authorization to make it Public. Changing visibility is not part of this review.

## Publication gate

1. Re-run CI, documentation validation, dependency/Brakeman scanning and synthetic search tests on the **exact candidate commit**.
2. Run a full credential scanner such as Gitleaks/TruffleHog on all Git history and review potential findings without including secrets in tickets. The current review used pattern-based heuristics only.
3. Audit GitHub Actions history/artifacts, releases, tags, external assets and GitHub secret/environment settings for unintended disclosure, including obsolete rewritten SHA references.
4. Verify fresh anonymous clone and link accessibility only **after** explicit public authorization.
5. Complete independent production host security, backup+restore and KEK custody acceptance before storing real credentials.

**Decision: the repository is NOT automatically approved for public visibility or production secret custody.** This review documents evidence and remaining gates rather than claiming independent penetration testing.
