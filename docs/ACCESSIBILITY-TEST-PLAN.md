# Accessibility acceptance test plan — v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](ACCESSIBILITY-TEST-PLAN.vi.md)

## Scope and prerequisites

Test the **exact release SHA** against the login, MFA, dashboard, vault list, create/edit, reveal, version history, account settings and sessions screens. Use fake secrets and a dedicated disposable account. Record browser/OS/device, viewport and assistive technology version.

The plan is a human-review checklist, **not** a claim of completed manual acceptance or WCAG certification. Its current manual sign-off category is **PENDING HUMAN** until a current, independently reviewed acceptance record is available.

## Acceptance scenarios

| ID | Scenario | Expected result |
| --- | --- | --- |
| A01 | Keyboard-only login and MFA | Controls reachable in logical order; understandable errors; no traps |
| A02 | Focus visibility and error recovery | Focus visible and restored predictably after submit/navigation |
| A03 | Screen-reader labels | Inputs/buttons have meaningful names; errors are discoverable |
| A04 | Vault list/search/filter | Control purpose, result updates and empty states are understandable |
| A05 | Secret reveal/re-hide | Status understandable; no accidental lingering plaintext in evidence |
| A06 | Modal and scrolling | Modal content and buttons usable at 320–390px widths |
| A07 | Mobile touch | No blocked controls, clipped input or horizontal scrolling regression |
| A08 | Reduced-motion/contrast | Content and focus remain perceivable with OS/browser preferences |
| A09 | Session revoke and MFA recovery | High-risk actions remain operable and clearly labeled |
| A10 | Zoom and responsive layout | At browser zoom and narrow widths, no critical functionality disappears |

## Procedure

1. Capture exact SHA and the device/browser/environment matrix.
2. Complete each scenario by keyboard, then with a screen reader, then on touch where applicable.
3. Record **PASS**, **FAIL**, or **PENDING** per ID; attach sanitized screenshots only.
4. File regressions with reproducible steps and owner; retest fixes at the new SHA.
5. Obtain separate operator sign-off before treating any specific deployment as accepted.

No old candidate's manual results should be relabeled as this release's proof. See [Accessibility overview](ACCESSIBILITY.md) and [Release qualification](qualification.md).
