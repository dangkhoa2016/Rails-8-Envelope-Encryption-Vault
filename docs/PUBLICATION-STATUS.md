# Publication status — RC 0.1.8.3

This note distinguishes the isolated candidate acceptance evidence from an actual production deployment.

## Verified

- Application request/service acceptance: 31 tests, 124 assertions, zero failures; separate synthetic session-cookie test: one test and eight assertions.
- Synthetic AWS KMS-backed HTTP E2E: login, encrypted create/reveal/update/restore, version history and audit events.
- Production Rails boot and isolated HTTP checks; localhost HTTPS proxy served the Rails login page and all 13 referenced CSS/JS assets.
- Static asset archive delivery was checked independently by SHA-256.

## Not yet verified

- Sealed RC 0.1.8.3 candidate-specific offhost roundtrip and full guarded promotion rehearsal.
- Actual live production hosting, hostname, public HTTPS, independent recovery custody and scheduled operations.
- Authenticated production-mode HTTPS login and the Secure session-cookie attribute. Test-mode checks established HttpOnly and SameSite=Strict separately.
- Production cutover, which has not been performed.

## Historical provenance

The proposal is a curated 11-commit history derived from 22 recovered commits. The original commit graph and sealed candidate are preserved separately; rewritten commit hashes must not be substituted into the original sealed release metadata.
