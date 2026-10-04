# FIX25 Release Notes — Showcase & Verification

FIX25 is forked from the accepted FIX24 baseline.

## Product / portfolio improvements

- Synthetic demo fixture built through the real envelope-encryption services.
- Six representative encrypted item types plus version-history data.
- Reproducible Selenium screenshot harness for desktop/mobile portfolio captures.
- Audit filtering by friendly category while preserving raw action filters.
- Architecture and threat-model Mermaid documentation.
- Accessibility verification document and one-command smoke script.
- README links to showcase/architecture/accessibility workflows.

## Recovery / operator improvements

Persistent runtime executable-mode repair now logs exactly which runtime tool is repaired instead of silently chmodding it.

## Security boundaries

- Demo data is fake only.
- Demo fixture requires DEMO_MODE=true.
- Rake fixture requires a mode-0600 password file.
- No public screenshot workflow reads recovery keys, KEKs, rclone config, or environment secret files.
- Audit category filtering does not weaken raw action semantics or metadata allowlisting.

FIX25 does not change the envelope-encryption format, KEK separation, MFA, reauthentication, encrypted tags, immutable encrypted history, or rate-limit model.
