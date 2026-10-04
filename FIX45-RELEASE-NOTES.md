# FIX45 Release Notes — Production Abuse Resistance & Rate-Limit Evidence

## Scope

FIX45 turns Rack::Attack configuration into production-mode release evidence and hardens throttle responses so blocked requests remain stateless.

## Changes

- Adds a dedicated `RateLimitBoundary` before Cookies/Session but after request-ID/logging middleware.
- Removes the duplicate/default Rack::Attack placement from the effective stack.
- Adds `script/production-rate-limit-preflight`.
- Proves login/IP throttle at 5 requests/minute.
- Proves normalized login/account throttle at 10 requests/10 minutes across distinct IPs.
- Proves global IP throttle at 300 requests/minute.
- Proves `/up` and `/ready` remain safelisted after global quota exhaustion.
- Proves 429 responses include `Retry-After`, use `Cache-Control: no-store`, and do not set a session cookie.
- Proves request-ID/log correlation and canary non-leakage.
- Records the production cache store class used by Rack::Attack.
- Integrates rate-limit evidence into release metadata, checklist, sealing, and off-host evidence.

## Evidence boundary

The preflight validates the configured production throttles and the exercised request paths. It does not claim protection against every possible distributed abuse pattern.

Manual accessibility remains pending.
