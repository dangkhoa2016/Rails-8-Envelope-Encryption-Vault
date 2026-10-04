# Ruby Envelope Vault 0.1.2-FIX40

## Scope

FIX40 adds production UX/accessibility preflight evidence while keeping human accessibility review explicitly separate.

## Changes

- Added browser-level production UX/accessibility system tests.
- Verified keyboard focus traversal and visible focus treatment.
- Verified assertive registration validation semantics.
- Added a 640px compact-layout reflow proxy for a 1280px desktop at 200% zoom.
- Verified browser-emulated reduced-motion handling.
- Increased primary mobile header targets to a practical minimum of 40px.
- Added `script/production-ux-accessibility-preflight`.
- Added non-secret `UX-ACCESSIBILITY-PREFLIGHT.json` release evidence.
- Added FIX40 manual evidence matrix and acceptance protocol.
- Release metadata/checklist distinguish automated PASS from `PENDING HUMAN`.
- Release metadata explicitly records that WCAG conformance is not claimed.

## Human review

Screen-reader walkthrough, full keyboard workflow judgment, layered contrast review, real touch-device usability and subjective focus-order review remain pending until actual human evidence is recorded.
