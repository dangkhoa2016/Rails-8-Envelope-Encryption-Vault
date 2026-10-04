# FIX43 Release Notes — Production Logging Redaction & Secret-Safe Observability

## Scope

FIX43 turns request-parameter redaction from static configuration into production-mode release evidence.

## Changes

- Added an isolated logging probe route enabled only by `LOGGING_PREFLIGHT_PROBE=true`.
- Added `script/production-logging-redaction-preflight`.
- Sends controlled canary values through sensitive request fields in a real production Rails server.
- Requires sensitive parameter keys to appear in logs only with Rails filtering markers.
- Fails if any plaintext canary appears in production logs.
- Proves request-ID/log correlation.
- Writes machine-readable evidence without secret values.
- Integrates logging-redaction evidence into release metadata, operator checklist, release sealing, and off-host evidence.

## Coverage

The current preflight verifies at least eight sensitive parameter classes:

- password
- secret value
- MFA/token
- email address
- environment text
- search query
- ciphertext
- nonce

## Evidence boundary

This preflight proves filtering for the exercised request parameters in the tested production logging path. It does not claim that every possible application log statement or external logging sink has been manually audited.

Manual accessibility remains pending and no WCAG conformance claim is introduced.
