# FIX42 Release Notes — Production Failure Handling & Safe Error Evidence

## Scope

FIX42 adds user-safe production handling for HTTP 404, 422, and 500 failures without mutating the accepted FIX41 release.

## Changes

- Added branded error responses for 404, 422, and 500.
- Added a dedicated minimal error layout independent of authenticated application state.
- Added production `exceptions_app` routing through Rails routes.
- Added controlled 422/500 probes that exist only when `ERROR_PREFLIGHT_PROBE=true`.
- Added `script/production-error-preflight`.
- Added request-ID correlation evidence across response body, response header, and production log.
- Added checks proving error bodies do not expose stack traces, application/runtime paths, or secret values.
- Added `Cache-Control: no-store` for error responses.
- Added release metadata/checklist integration for failure-handling evidence.
- Removed the FIX41 hardcode from isolated-restore release sealing by deriving the release directory from `VERSION`.

## Evidence boundary

The failure-handling preflight validates controlled production-mode failures. It does not claim that every possible exception class has been manually exercised.

Manual accessibility status remains pending; FIX42 does not change the FIX40 accessibility evidence boundary.
