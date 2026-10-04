# DEV-0.1.6 Milestone 1 — Release Truth and Provenance

## Scope

This milestone reconciles repository documentation with the accepted 0.1.5 release and establishes a clean 0.1.6 development baseline. It changes documentation/provenance only; no application behavior, schema, routes, dependencies, crypto, MFA, or session semantics are changed.

## Stable baseline

- sealed stable release: `RELEASE-0.1.5`
- live `current`: `/content/RELEASE-0.1.5`
- development workspace: `/content/DEV-0.1.6`
- development version: `0.1.6-dev`

## Changes

- Added `docs/ROADMAP-0.1.6.md`.
- Updated README current-release quality from stale 0.1.3 wording to accepted 0.1.5 facts.
- Converted 0.1.5 candidate notes to stable-release notes.
- Added a 0.1.6 changelog entry with the verified baseline.
- Preserved manual accessibility as PENDING and explicitly avoided a WCAG conformance claim.
- Kept AWS KMS production-support claims gated pending evidence reconciliation.

## Verification

- repository policy: PASS
- portability policy: PASS
- documentation links: `DOC_LINK_CHECK=PASS checked=33`
- stable `current` target unchanged: `RELEASE-0.1.5`
- stable live health: HTTP 200
- stable sealed-source integrity: `PASS files=366`

Milestone verdict: **PASS / COMPLETE**.

## Boundary

This documentation-only milestone did not modify the accepted stable release. Manual accessibility remains a human evidence task and is intentionally not marked complete by automation.
