# FIX40 Accessibility Evidence Matrix

This matrix keeps automated evidence separate from human accessibility review. FIX40 does **not** claim WCAG conformance.

| Area | Automated evidence | Human status | Notes |
|---|---|---|---|
| Keyboard entry/focus | PASS | PENDING HUMAN | Browser test verifies autofocus → Shift+Tab → skip link and visible focus treatment |
| Full keyboard workflow | PARTIAL PASS | PENDING HUMAN | Human must traverse CRUD, MFA, sessions, dialogs/actions |
| Focus visibility | PASS | PENDING HUMAN | Browser checks outline or focus ring on keyboard-focused skip link |
| Screen reader | NOT AUTOMATED | PENDING HUMAN | Record actual screen reader/browser used |
| Contrast | NOT CLAIMED | PENDING HUMAN | Layered/translucent UI requires manual/tool-assisted review |
| 200% zoom/reflow | PASS PROXY | PENDING HUMAN | 640px viewport proxy covers core routes; manual browser zoom still recommended |
| Mobile overflow | PASS | PENDING HUMAN | Existing 390px smoke remains automated |
| Primary touch targets | PASS | PENDING HUMAN | Header primary controls are at least 40px in compact layout |
| Validation errors | PASS | PENDING HUMAN | Assertive registration error container verified |
| Reduced motion | PASS | PENDING HUMAN | Chrome media emulation verifies reduced-motion CSS activation |
| Demo banner | PASS | OPTIONAL | Existing synthetic-data banner system coverage |
## Human sign-off template

Do not edit a row to PASS without completing the relevant walkthrough.

| Check | Status | Browser / AT / device | Evidence / defect |
|---|---|---|---|
| Screen reader | PENDING | — | — |
| Full keyboard workflow | PENDING | — | — |
| Layered contrast | PENDING | — | — |
| Real touch device | PENDING | — | — |
| 200% browser zoom spot-check | PENDING | — | — |
| Focus-order usability | PENDING | — | — |

## Interpretation

`PASS` in the automated column means only that the named machine check passed.

`PENDING HUMAN` is intentional evidence of an unfinished human review, not a failure and not a pass.

A future release may change a human row to PASS only when browser/device/assistive-technology evidence is recorded.
