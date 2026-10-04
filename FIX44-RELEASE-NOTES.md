# FIX44 Release Notes — CSRF Origin Validation & Cross-Site Request Rejection

## Scope

FIX44 strengthens production CSRF protection by enabling Rails origin validation and adds production-mode release evidence for same-origin acceptance and cross-site rejection.

## Changes

- Enables `config.action_controller.forgery_protection_origin_check = true` in production.
- Adds `script/production-csrf-origin-preflight`.
- Fetches a real CSRF token and session cookie from an isolated production server.
- Proves that a same-origin request with a valid token is accepted by the CSRF layer.
- Proves that a foreign origin is rejected with HTTP 422.
- Proves that `Origin: null` is rejected with HTTP 422.
- Proves that a request missing the authenticity token is rejected with HTTP 422.
- Requires request-ID/log correlation.
- Requires branded 422 handling without internal CSRF diagnostics.
- Writes secret-free machine-readable evidence.
- Integrates CSRF evidence into release metadata, operator checklist, release sealing, and off-host evidence.

## Evidence boundary

The preflight exercises the Rails session POST path in isolated production mode. It validates the application-level CSRF/origin contract for the tested path; it does not claim to replace browser/vendor-specific security testing.

Manual accessibility remains pending and no WCAG conformance claim is introduced.
