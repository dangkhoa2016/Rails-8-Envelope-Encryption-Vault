# FIX25 Accessibility Verification

FIX25 keeps accessibility work explicit and testable without claiming formal WCAG conformance.

## Current verified behaviors

- skip-to-content link;
- main-content landmark;
- active navigation with `aria-current`;
- mobile navigation `aria-controls` and `aria-expanded`;
- global `:focus-visible` treatment;
- reduced-motion CSS handling;
- registration validation summary with alert semantics;
- keyboard-operable native form controls;
- desktop/mobile Selenium coverage.

## Automated smoke command

Run:

```bash
./script/accessibility-smoke
```

It executes the accessibility/navigation system test plus static recovery-contract checks for focus-visible and reduced-motion rules.

## Limitations

Automated checks do not prove WCAG conformance. A formal review should still include:

- keyboard-only walkthrough;
- screen-reader walkthrough;
- color-contrast measurement;
- zoom/reflow testing;
- touch-target review;
- validation-message association review;
- reduced-motion manual verification.
