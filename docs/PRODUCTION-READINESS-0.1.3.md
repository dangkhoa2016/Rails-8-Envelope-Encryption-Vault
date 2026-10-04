# Production Readiness Matrix — 0.1.3

This matrix summarizes the evidence expected for the 0.1.3 milestone. The release metadata remains the machine-readable source of truth.

| Area | Runtime evidence | Required state |
|---|---|---|
| Repository / portability | repository-policy, portability-check, doc-link-check | PASS |
| Rails behavior | Rails + system tests | PASS |
| Static/security scanning | RuboCop, Brakeman, bundler-audit | PASS |
| Cryptography | crypto-self-test, security-self-test | PASS |
| UX/accessibility automation | UX-ACCESSIBILITY-PREFLIGHT | PASS |
| Manual accessibility | human evidence | PENDING; no WCAG claim |
| HTTP security | HTTP-SECURITY-PREFLIGHT | PASS |
| Failure handling | ERROR-CORRELATION-PREFLIGHT | PASS |
| Logging redaction | LOGGING-REDACTION-PREFLIGHT | PASS |
| CSRF/origin | CSRF-ORIGIN-PREFLIGHT | PASS |
| Abuse resistance | RATE-LIMIT-PREFLIGHT | PASS |
| Session lifecycle | SESSION-LIFECYCLE-PREFLIGHT | PASS |
| FIX46 upgrade compatibility | UPGRADE-FROM-FIX46-PREFLIGHT | PASS |
| New-host recovery | NEW-HOST-RECOVERY-SUMMARY | PASS |
| Isolated restore | release seal restore | PASS |
| Public package integrity | PUBLIC-PACKAGE-INTEGRITY | PASS |
| Source immutability | SEALED-SOURCE-SHA256SUMS | PASS |
| Promotion discipline | explicit promotion stop + postpromote evidence | PASS |
| Off-host durability | upload/download SHA-256 round-trip | PASS |

## Production claim boundary

Passing this matrix establishes a repeatable software release and recovery contract for the tested environments. It does not make Kaggle a recommended production host, does not replace independent KEK custody, and does not convert automated accessibility checks into a formal WCAG conformance claim.

## Milestone intent

0.1.3 is a consolidation release: the primary change is converting the long FIX-series evidence into one coherent milestone, upgrade path and readiness record rather than adding new product behavior.
