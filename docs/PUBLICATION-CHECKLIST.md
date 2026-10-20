# Publication checklist — Ruby Envelope Vault RC 0.1.8.3

This branch is a **review draft**, not the sealed RC release and not an already promoted production system.

## Complete

- [x] Draft separate from original 22-commit and condensed 11-commit Git histories.
- [x] README reflects the RC 0.1.8.3 status rather than the obsolete 0.1.5 development line.
- [x] Publication status explicitly lists remaining release gates.
- [x] Historical engineering documentation has its own index.
- [x] Basic heuristic scans of final tracked files and 472 historical blob entries found no common private-key or token patterns.
- [x] Original Git trees and backup archive preserved.

## Blocking publication

- [x] Owner confirmed MIT License, copyright 2026 Đăng Khoa <i.am@dangkhoa.dev>; LICENSE added to draft.
- [x] Configure future publication commit identity as Đăng Khoa <i.am@dangkhoa.dev>.
- [ ] Review attribution of historical commits separately; original bot/release aliases preserved for provenance.
- [ ] Review Dockerfile and ops/*.env.example to ensure all database credentials are sample values.
- [ ] Review historical development documentation as a publication collection; do not erase authentic chronology or claim historical evidence is newer.
- [ ] Run full history secret scanning with a dedicated scanner and human review before publishing.
- [ ] Configure the intended GitHub owner/repository and authenticate GitHub CLI.
- [ ] Commit new documentation at its actual timestamp, with an explicitly confirmed contributor identity.
- [ ] Re-run final scope-specific application checks and inspect license/release links.

## Safety

No production promotion, GitHub push, tag rewrite, or sealed release metadata mutation is authorized by this checklist.


## Verified scanner triage — 2026-10-20

- Dedicated Gitleaks scan: five generic API-key findings in the existing history. None was silently allowlisted or hidden.
- Documentation password and production environment values contain explicit placeholder markers; production configuration still requires operator-created secrets.
- Log-redaction canary intentionally uses a synthetic value to test filtering.
- RFC TOTP test constants are deterministic published test vectors needed for cryptographic regression checks.
- The above classification does not certify the absence of other undiscovered secrets. Keep a private review record of scan reports; never publish raw Gitleaks result values.
- Historical concrete Cloudflare Tunnel URL and generated Python bytecode were removed from all commits in the curated public history.
