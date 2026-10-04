# Production Failure Handling — FIX42

## Objective

Provide non-technical users with safe, useful production error pages while preserving operational correlation for maintainers.

## User-facing contract

The production application handles:

- **404** — unknown or missing resource.
- **422** — invalid, stale, or unprocessable request.
- **500** — unexpected internal failure.

Each response uses fixed user-safe copy, a useful return-to-sign-in action, and a request support reference. Exception messages and backtraces are never rendered.

## Correlation contract

Rails already tags production logs with the request ID. FIX42 exposes the same request ID as a non-secret support reference on the error page and preserves the `X-Request-Id` response header.

The isolated production preflight sends deterministic request IDs and requires the same ID to appear in:

1. the rendered error response,
2. the response request-ID header,
3. the production server log.

## Safe evidence

`script/production-error-preflight` boots an isolated production server and proves:

- 404, 422, and 500 status codes,
- branded fixed-copy error pages,
- request/log correlation,
- no stack trace or exception-class leakage in response bodies,
- no application/runtime path leakage in response bodies,
- no configured database, Redis, application-secret, KEK, or recovery-key value leakage in response bodies,
- `Cache-Control: no-store`,
- machine-readable evidence with `contains_secret_values=false`.

Controlled 422 and 500 probe routes are loaded only when `ERROR_PREFLIGHT_PROBE=true`; they are not part of normal production routing.

## Release evidence

Expected artifacts:

- `ERROR-CORRELATION-PREFLIGHT.json`
- `ERROR-CORRELATION-PREFLIGHT.log`

The release metadata must record the three status codes, request-ID correlation PASS, leakage booleans, and SHA-256 of the JSON evidence.

## Existing invariants preserved

FIX41 remains immutable. HTTP security, automated UX/accessibility, new-host recovery, isolated restore, sealed-source integrity, explicit promotion, and off-host round-trip remain mandatory release gates.

Manual accessibility remains **PENDING** and no WCAG conformance claim is introduced.
