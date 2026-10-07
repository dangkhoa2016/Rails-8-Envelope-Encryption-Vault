# DEV 0.1.8.3 — Milestone 4 Manual Accessibility Acceptance Worksheet

Date prepared: 2026-10-07  
Release: `0.1.8.3-dev`

## Automated preflight

Latest automated preflight on Kaggle:

- keyboard focus traversal: PASS
- visible focus treatment: PASS
- validation error semantics: PASS
- 200% reflow proxy: PASS
- primary mobile target size: PASS
- reduced-motion browser preference: PASS
- `UX_ACCESSIBILITY_PREFLIGHT=PASS`

The automated evidence explicitly records:

- `manual_accessibility_complete=false`
- `wcag_conformance=false`

Automated PASS must not be converted into manual PASS.

## Human checks

For every row, record the date, browser/version, OS, assistive technology or physical device where relevant, routes/workflows exercised, PASS/FAIL, and concise evidence or defect reference.

### 1. Screen-reader walkthrough

Status: PENDING

Record:

- Date:
- Browser + version:
- OS:
- Screen reader + version:
- Routes/workflows:
- Result: PENDING
- Evidence/defect reference:

Exercise at minimum:

- sign-in/registration validation;
- primary navigation and skip link;
- vault item list/detail;
- create/edit/delete confirmation;
- MFA/session/security messaging.

### 2. Full keyboard-only workflow judgment

Status: PENDING

Record:

- Date:
- Browser + version:
- OS:
- Routes/workflows:
- Result: PENDING
- Evidence/defect reference:

Judge:

- logical focus order;
- no keyboard traps;
- all actionable controls reachable;
- visible focus remains clear;
- dialogs/menus return focus sensibly;
- CRUD/MFA/session flows can be completed without pointer input.

### 3. Layered/gradient color-contrast review

Status: PENDING

Record:

- Date:
- Browser + version:
- OS/display:
- Routes/components:
- Result: PENDING
- Evidence/defect reference:

Review text/icons/focus treatment where gradients, transparency, overlays, hover/focus state, or layered backgrounds make computed CSS checks insufficient.

### 4. Real touch-device usability

Status: PENDING

Record:

- Date:
- Device model:
- OS + version:
- Browser + version:
- Routes/workflows:
- Result: PENDING
- Evidence/defect reference:

Judge:

- mobile navigation toggle;
- header New-item action;
- form controls;
- destructive confirmations;
- scrolling/reflow;
- target spacing and accidental activation risk.

### 5. Subjective focus usability

Status: PENDING

Record:

- Date:
- Browser + version:
- OS:
- Routes/workflows:
- Result: PENDING
- Evidence/defect reference:

Judge whether focus order is understandable and focus indication is visually obvious in realistic workflows, not merely technically present.

## Sign-off rule

A manual FAIL blocks production-UX sign-off until the issue is fixed and retested.

Milestone 4 can be marked PASS only after all five human checks have actual recorded evidence.

Until then:

- `UX_ACCESSIBILITY_MANUAL_STATUS=PENDING`
- WCAG conformance is NOT claimed.
