# Manual Accessibility Evidence — DEV-0.1.6

## Status

**PENDING HUMAN REVIEW**

Automated browser evidence is PASS. This worksheet does not claim WCAG conformance and must not be changed to human PASS without an actual walkthrough.

## Review build

- version: `0.1.6-dev`
- workspace: `/content/DEV-0.1.6`
- sealed stable base: `RELEASE-0.1.5`
- review database: isolated synthetic demo database
- demo data: synthetic/example-only
- review server: separate DEV server on port 3016
- live stable release remains on port 3000

## Automated baseline

- production UX/accessibility preflight: PASS
- keyboard focus traversal: PASS (automated)
- visible focus treatment: PASS (automated)
- validation error semantics: PASS (automated)
- 200% reflow proxy: PASS (automated)
- primary mobile target-size check: PASS (automated)
- reduced-motion emulation: PASS (automated)
- evidence: `tmp/a11y-review-016/UX-ACCESSIBILITY-PREFLIGHT.json`

## Human review access

Temporary review URL:
`https://<temporary-demo-tunnel.example>`

Synthetic demo account:
- email: `showcase@example.test`
- password: `showcase-demo-password-1234`

This account and its Vault contents are synthetic demo data only. The review database is isolated from the live stable release and the ordinary development database.

## Human review checklist

Record PASS/FAIL plus a short note for each item.

| Check | Status | Browser / AT / device | Evidence / defect |
|---|---|---|---|
| Keyboard-only login and primary navigation | PENDING | — | — |
| Vault list/search/filter keyboard workflow | PENDING | — | — |
| Create/edit form keyboard workflow | PENDING | — | — |
| Reveal/reauth interaction and copy feedback | PENDING | — | — |
| Security/MFA/settings navigation | PENDING | — | — |
| Sessions and Audit navigation/actions | PENDING | — | — |
| Visible and sensible focus order | PENDING | — | — |
| 200% browser zoom / reflow | PENDING | — | — |
| Screen-reader smoke | PENDING | — | — |
| Layered/gradient contrast review | PENDING | — | — |
| Real touch-device usability | PENDING | — | — |

## Review findings — 2026-10-03

Human review identified two defects:

1. Login template icon was visually misleading. After a second visual review, the intermediate credential/ID-card glyph was replaced with a cleaner sign-in doorway/arrow SVG that reads more clearly at 16–20px.
2. Favorites Search could fail through the public review URL with `ActionController::InvalidAuthenticityToken` because `Referrer-Policy: no-referrer` caused an opaque/`null` origin for the POST search while Rails origin-based CSRF checks were enabled.

Resolution for issue 2:
- changed document/production/Caddy referrer policy to `same-origin`;
- kept Rails `forgery_protection_origin_check=true` (not disabled);
- updated HTTP security smoke/preflight expectations and documentation;
- focused Vault system test: 1 run / 34 assertions / PASS;
- production HTTP-security preflight: PASS;
- real Chrome via the public Cloudflare review URL: `PUBLIC_BROWSER_REFERRER_POLICY=PASS value=same-origin` and `PUBLIC_BROWSER_FAVORITES_SEARCH=PASS`.

Human review remains PENDING for the remaining checklist items.

### Responsive Dashboard defect fixed

Human review found the right-side Security posture card became cramped at medium desktop widths because the Dashboard switched to a two-column content grid at the Tailwind `xl` viewport breakpoint even though the persistent 260px application sidebar had already reduced available content width.

Resolution:
- Dashboard main content now remains a single column below 1536px;
- two-column Dashboard composition begins at 96rem/1536px;
- the secondary column uses a minimum width of 340px;
- Security settings/status controls use shrink protection;
- MFA/session status text is explicitly non-wrapping;
- regression coverage added for a 1365×900 viewport.

Verification:
- focused production UX/accessibility system suite: 6 runs / 37 assertions / PASS;
- real Chrome through public review tunnel at 1365×900:
  - `PUBLIC_DASHBOARD_NO_OVERFLOW=PASS`
  - Dashboard columns: one track
  - `PUBLIC_SECURITY_POSTURE_NOWRAP=PASS`
  - MFA status badge height: 24px.

## Human review result — 2026-10-03

Reviewer feedback:

> Overall review completed; the interface and workflows were reported as looking quite good, with no blocking usability/accessibility issue reported.

Recorded interpretation:

- human review performed: YES
- overall usability/accessibility impression: POSITIVE
- blocking issue reported: NO
- remediation required from this review: NONE
- formal WCAG conformance claimed: NO
- automated accessibility evidence remains independently PASS

Evidence boundary:

This feedback supports an overall human-review acceptance with no blocker reported. It does **not** by itself prove that every assistive-technology-specific row below was exercised. Screen-reader, real-touch-device, detailed contrast, and other checks that were not explicitly described by the reviewer must not be silently upgraded to a standalone PASS claim.

## Human-review summary status

**HUMAN REVIEW COMPLETE — NO BLOCKERS REPORTED**

Granular assistive-technology evidence: **NOT SEPARATELY RECORDED**

