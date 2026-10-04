# Production Rate Limiting — FIX45

## Objective

Demonstrate that production abuse controls work at runtime and that throttle responses remain stateless and non-sensitive.

## Middleware boundary

FIX45 places a single `RateLimitBoundary` after request-ID, remote-IP, and logging middleware, but before cookies and session middleware.

This preserves request correlation while preventing a blocked 429 request from creating or refreshing an application session cookie.

## Runtime evidence

`script/production-rate-limit-preflight` verifies:

- login/IP: first five requests continue normally; sixth returns 429,
- login/account: ten requests across distinct IPs using differently cased/spaced email values continue; the normalized eleventh request returns 429,
- global/IP: first 300 requests pass; request 301 returns 429,
- health safelist: `/up` and `/ready` remain 200 after global quota exhaustion,
- 429 includes `Retry-After`,
- 429 uses `Cache-Control: no-store`,
- 429 does not emit `Set-Cookie`,
- request-ID/log correlation remains available,
- synthetic credential canaries do not appear in logs,
- evidence contains no secret values.

The production cache backend is recorded from `Rails.cache.class.name`; FIX45 does not assume Redis when production is configured to use another Rails cache store.

## Evidence

Canonical files:

- `RATE-LIMIT-PREFLIGHT.json`
- `RATE-LIMIT-PREFLIGHT.log`

All prior release gates remain mandatory.
