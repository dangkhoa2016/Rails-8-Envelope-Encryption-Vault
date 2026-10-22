# Accessibility engineering and review — v1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](ACCESSIBILITY.vi.md)

## Scope and release boundary

The Vault interface includes interactive authentication, MFA, secret reveal, item editing, history, and session-management screens. Accessible behavior matters especially because an error can prevent a user from safely retrieving or managing security-critical information.

Automated system tests exercise keyboard navigation, focus behavior, responsive/mobile boundaries and other targeted UX behavior. The project does not claim formal WCAG conformance. However, **no formal WCAG conformance or manual accessibility acceptance for this v1.0.0 release is claimed**. Older manual evidence belongs to its original source candidate and should not be relabeled.

## Review matrix

| Dimension | What to verify | Evidence method |
| --- | --- | --- |
| Keyboard | Tab order, Enter/Space activation, no focus traps | Manual keyboard walkthrough and Rails system tests |
| Focus | Focus visible after submit, dialog close and navigation | Browser observation and screenshots without secrets |
| Screen readers | Names, roles, labels, announcements, form errors | Narrator/NVDA/VoiceOver review on the actual release |
| Contrast | Text, controls, status and focus ring readability | Visual measurement in each supported theme |
| Reduced motion | Avoid disruptive movement and unintended focus shifts | OS preference and browser testing |
| Responsive/touch | Forms, modal scrolling, overflow and target sizes | Real mobile browser and automated layout checks |
| Security UI | Reveal control, MFA fields, recovery-code handling | Safe end-to-end synthetic user walkthrough |

## Manual acceptance procedure

1. Record exact Git SHA, browser, OS, device and zoom level.
2. Navigate login, MFA challenge, dashboard, vault list, item creation/editing, reveal and version history **without a mouse**.
3. Check correct accessible labels, focus indication, informative errors, and recovery from invalid input.
4. Repeat with a screen reader and at narrow mobile widths.
5. Review high-contrast/reduced-motion settings and avoid screenshots containing plaintext.
6. Log findings with severity, reproduction steps and sanitized evidence.
7. Mark results **PASS**, **FAIL** or **PENDING** by scenario; do not declare an overall certification from a subset.

See the [Detailed test plan](ACCESSIBILITY-TEST-PLAN.md) and [Qualification matrix](qualification.md).

## Evidence status

Manual acceptance for the initial source release is **PENDING** unless a deployment-specific current evidence file has been independently reviewed. The tooling can accept a manually reviewed evidence path via `UX_ACCESSIBILITY_MANUAL_EVIDENCE_FILE`; setting that variable alone does **not** prove the content is valid.

Security and usability both matter; see the [Security policy](SECURITY.md) for reporting sensitive issues.
