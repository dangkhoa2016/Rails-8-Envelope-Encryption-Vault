# Ruby Envelope Vault — Public Portfolio Landing

A production-style Rails 8 personal secrets vault focused on envelope encryption, immutable history, MFA/session hardening, recovery discipline, and evidence-driven releases.

## At a glance

- **5 purpose-built secret flows:** Login, Note, API Key, Environment, generic Secret.
- **10 synthetic showcase screenshots:** 8 desktop + 2 mobile views.
- **4 canonical release artifacts:** migration bundle, source ZIP, screenshot bundle, sanitized public showcase.
- **2 evidence provenance models:** legacy evidence for pre-metadata releases and metadata-native evidence for newer releases.
- **Explicit trust boundary:** server-side envelope encryption; not zero knowledge.
- **Explicit promotion boundary:** pre-promotion sealing stops at `PROMOTION_REQUIRED=yes`.

## Start here

1. [`../README.md`](../README.md) — project overview and security model.
2. [`ARCHITECTURE-OVERVIEW-FIX33.md`](ARCHITECTURE-OVERVIEW-FIX33.md) — Mermaid architecture and encryption flows.
3. [`ARCHITECTURE-THREAT-MODEL-FIX25.md`](ARCHITECTURE-THREAT-MODEL-FIX25.md) — threat model and trust assumptions.
4. [`PUBLIC-PORTFOLIO-INDEX-FIX33.md`](PUBLIC-PORTFOLIO-INDEX-FIX33.md) — complete screenshot gallery and review path.
5. [`PUBLIC-RELEASE-HISTORY.md`](PUBLIC-RELEASE-HISTORY.md) — sanitized release provenance and artifact integrity.
6. [`RELEASE-WORKFLOW-FIX31.md`](RELEASE-WORKFLOW-FIX31.md) — pre-promotion and post-promotion evidence workflow.
7. [`PRODUCTION-UX-ACCESSIBILITY-ACCEPTANCE-FIX40.md`](PRODUCTION-UX-ACCESSIBILITY-ACCEPTANCE-FIX40.md) — automated UX/accessibility preflight versus pending human review.
8. [`PRODUCTION-HTTP-SECURITY-FIX41.md`](PRODUCTION-HTTP-SECURITY-FIX41.md) — production-mode HTTP headers, cookie flags, TLS redirects, and health-endpoint contract.

## Evidence philosophy

Security and release claims in this portfolio are tied to automated tests, isolated restore, artifact checksums, and off-host round-trip verification. Automated UX/accessibility preflight evidence remains separate from human accessibility sign-off; pending human checks and the absence of a WCAG-conformance claim are explicit.
