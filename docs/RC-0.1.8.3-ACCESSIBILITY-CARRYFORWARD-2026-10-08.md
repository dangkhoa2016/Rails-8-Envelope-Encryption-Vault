# RC 0.1.8.3 — Accessibility evidence carryforward

Date: 2026-10-08

## Decision

The project operator accepted reusing the five completed DEV 0.1.8.3 accessibility
checks for the RC 0.1.8.3 release, because the RC was created from DEV without
application-code changes. This is a carryforward acceptance, **not** a second
human manual test or an independent accessibility audit.

## Source and traceability

- Original DEV version: 0.1.8.3-dev
- DEV Git HEAD: 8113262ff86f98e4d8e97d7b85c1a4c785125b69
- Initial RC Git HEAD: 27fd19f8a5f27f5acd24aeba051921e125793372
- Compared Git change: only VERSION, from 0.1.8.3-dev to 0.1.8.3
- Original evidence: docs/UX-ACCESSIBILITY-MANUAL-EVIDENCE-0.1.8.3-dev.json
- RC-version evidence: docs/UX-ACCESSIBILITY-MANUAL-EVIDENCE-0.1.8.3.json
- Source evidence SHA-256: d502e2de47b6c67fa92175e67e1daf00ef832324afe9f1be6587ef4bc682db17
- Original user-reported manual testing date: 2026-10-07
- Operator-approved carryforward date: 2026-10-08

## Checks carried forward

1. Screen-reader walkthrough — PASS (Narrator / Windows 10).
2. Full keyboard workflow judgment — PASS.
3. Layered/gradient contrast review — PASS.
4. Real Android touch-device usability — PASS (Samsung Android / Chrome).
5. Subjective focus usability — PASS.

No unresolved manual defects were reported in the DEV source evidence. The
source evidence retains its original tester descriptions, platform limitations
and unknown device/browser version details.

## Claim boundaries

- This record DOES NOT claim new RC manual testing.
- It does not claim any formal WCAG conformance or certification.
- The carryforward is only valid while the application code and relevant UI
  are unchanged relative to the tested DEV commit.
- If the RC introduces functional or UI changes, re-evaluate this acceptance
  and run appropriately scoped manual tests before promoting.

The version-specific preflight may now set
UX_ACCESSIBILITY_MANUAL_STATUS=COMPLETE_NO_BLOCKERS based on this
traceable, operator-approved evidence; automated checks are independent.
