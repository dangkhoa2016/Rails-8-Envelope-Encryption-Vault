# Production Logging Redaction — FIX43

## Objective

Ensure production observability remains useful for request correlation without logging sensitive plaintext values handled by Ruby Envelope Vault.

## Existing filtering policy

The application treats passwords, tokens, vault fields, search queries, identities, environment text, ciphertext metadata, and related values as sensitive through Rails parameter filtering.

FIX43 adds runtime evidence instead of relying only on initializer inspection.

## Preflight design

`script/production-logging-redaction-preflight` starts an isolated production server and enables a probe endpoint only for the duration of the preflight.

The probe receives distinct synthetic canary values for multiple sensitive parameter names. The preflight captures the production server log and requires:

1. HTTP 204 from the probe.
2. The supplied request ID to be present in the production log.
3. Sensitive parameter keys to be represented in the logged request.
4. Rails filtering markers to cover the exercised sensitive fields.
5. No plaintext canary value to appear anywhere in the captured server log.

The temporary raw server log is deleted when the preflight exits.

## Evidence

Canonical evidence files:

- `LOGGING-REDACTION-PREFLIGHT.json`
- `LOGGING-REDACTION-PREFLIGHT.log`

The JSON records only status, counts, checked parameter names, request-ID correlation, and non-leakage booleans. It does not contain canary secret values.

## Release contract

FIX43 release metadata requires:

- logging redaction preflight PASS,
- probe HTTP 204,
- request-ID/log correlation PASS,
- minimum sensitive-field coverage,
- plaintext canary exposure = false,
- secret values absent = true,
- SHA-256 of the JSON evidence.

## Boundaries

The probe route exists only when `LOGGING_PREFLIGHT_PROBE=true`.

This evidence covers the Rails request logging path exercised by the preflight. It is not a blanket claim about every future custom logger or third-party logging sink.

All prior release gates remain mandatory, including HTTP security, failure handling, automated UX/accessibility, new-host recovery, isolated restore, sealed-source integrity, explicit promotion, and off-host round-trip.
