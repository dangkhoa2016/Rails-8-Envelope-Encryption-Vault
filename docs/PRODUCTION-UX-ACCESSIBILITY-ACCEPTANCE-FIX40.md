# FIX40 Production UX + Accessibility Acceptance

FIX40 separates **automated browser evidence** from **human/manual evidence**. It does not claim formal WCAG conformance.

## Automated preflight

Run:

```bash
./script/production-ux-accessibility-preflight
```

The preflight rebuilds Tailwind, runs the FIX40 browser acceptance tests, and writes:

```text
UX-ACCESSIBILITY-PREFLIGHT.json
UX-ACCESSIBILITY-PREFLIGHT.log
```

Automated PASS covers:
- keyboard focus traversal to the skip link;
- visible focus treatment;
- assertive registration validation semantics;
- 640px compact reflow proxy for a 1280px desktop viewed at 200%;
- minimum 40px primary mobile header targets;
- browser-emulated reduced-motion preference.
## Human evidence still required

The following must remain `PENDING` until a person actually performs them:

- screen-reader walkthrough with named assistive technology;
- full keyboard-only workflow judgment across CRUD/MFA/session flows;
- layered/gradient color-contrast review where computed CSS checks are insufficient;
- real touch-device usability;
- subjective clarity of focus order and visible focus.

Passing the automated preflight must never silently convert these rows to PASS.

## Manual recording rule

For each human check, record:
- date;
- browser and version;
- operating system;
- assistive technology/device where applicable;
- route/workflow exercised;
- PASS/FAIL;
- concise evidence or defect reference.

A FAIL blocks a production-UX sign-off until fixed and retested.
## Current FIX40 UX changes

The mobile navigation toggle and header New-item action now provide a minimum 40px target dimension in compact layouts.

This is a practical product UX target used by this project; it is not presented as a standalone WCAG conformance claim.

## Release interpretation

`UX_ACCESSIBILITY_PREFLIGHT=PASS` means the automated browser preflight passed.

`UX_ACCESSIBILITY_MANUAL_STATUS=PENDING` means human accessibility acceptance is intentionally incomplete.

The release metadata must preserve both facts independently.
