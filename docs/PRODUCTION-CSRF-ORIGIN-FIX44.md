# Production CSRF Origin Validation — FIX44

## Objective

Require both Rails authenticity-token validation and same-origin request provenance for state-changing production requests.

## Production configuration

FIX44 enables:

`config.action_controller.forgery_protection_origin_check = true`

This causes Rails to reject requests whose `Origin` does not match the request base URL, including the opaque origin value `null`.

## Runtime preflight

`script/production-csrf-origin-preflight` starts an isolated production server, retrieves the real sign-in form and CSRF token, maintains the real session cookie, and exercises four cases:

1. Same-origin request + valid CSRF token — must pass the CSRF layer and continue to normal authentication handling.
2. Foreign origin + valid CSRF token — must return 422.
3. `Origin: null` + valid CSRF token — must return 422.
4. Same-origin request without CSRF token — must return 422.

Rejected requests must render the branded 422 page and must not expose Rails exception classes or CSRF diagnostic internals.

## Evidence

Canonical files:

- `CSRF-ORIGIN-PREFLIGHT.json`
- `CSRF-ORIGIN-PREFLIGHT.log`

The machine-readable evidence records only statuses, booleans, request-ID correlation, and non-leakage claims. Synthetic credential canaries are not retained.

## Release contract

Release metadata requires:

- CSRF origin preflight PASS,
- origin validation enabled,
- same-origin valid-token request accepted,
- foreign origin = 422,
- null origin = 422,
- missing token = 422,
- request-ID/log correlation PASS,
- secret values absent,
- SHA-256 of the JSON evidence.

## Boundaries

This validates Rails' production CSRF/origin behavior for the exercised state-changing route. Reverse-proxy correctness, DNS, TLS termination, and browser policy are still deployment concerns.

All prior gates remain mandatory: HTTP security, safe failure handling, logging redaction, automated UX/accessibility, new-host recovery, isolated restore, sealed-source integrity, explicit promotion, and off-host round-trip.
