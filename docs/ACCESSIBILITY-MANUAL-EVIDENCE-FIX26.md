# FIX26 Accessibility Manual Evidence Checklist

This checklist records manual evidence separately from automated accessibility smoke tests. It does **not** claim WCAG conformance.

| Area | Manual check | Status | Evidence / notes |
|---|---|---|---|
| Keyboard-only | Reach sign-in, primary navigation, vault actions, forms, dialogs and sign-out without a pointer | PENDING | Run on final FIX26 build |
| Focus visibility | Every interactive element has a visible focus indicator | PENDING | Run on final FIX26 build |
| Screen reader | Landmarks, labels, headings, statuses and validation errors are announced meaningfully | PENDING | Test with an available screen reader |
| Contrast | Review text, controls, badges and focus indicators | PENDING | Manual/tool-assisted review required |
| Zoom/reflow | 200% zoom without loss of core content/actions | PENDING | Desktop browser |
| Mobile reflow | 390px viewport has no unintended horizontal scrolling | AUTOMATED PASS | Covered by system smoke; manual spot-check still recommended |
| Touch targets | Primary mobile controls are practically tappable | PENDING | Mobile/emulation review |
| Validation errors | Error summary and invalid fields are understandable and announced | PENDING | Registration/settings forms |
| Reduced motion | Motion is reduced when `prefers-reduced-motion` is enabled | STATIC/AUTOMATED PASS | CSS contract exists; manual OS/browser verification pending |
| Demo banner | Synthetic-data-only warning is visible and understandable | AUTOMATED PASS | `demo_mode_banner_test.rb` |

Only change PENDING rows to PASS after an actual manual check and record the browser/assistive technology used.
