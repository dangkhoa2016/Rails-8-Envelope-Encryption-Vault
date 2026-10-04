# Ruby Envelope Vault 0.1.2-FIX41

## Scope

FIX41 adds production-mode HTTP transport and browser-security evidence as a release gate.

## Changes

- Added `script/production-http-security-preflight`.
- Production preflight boots the real Rails production stack on an isolated local port.
- Verifies CSP with nonces and restrictive source directives.
- Verifies HSTS, frame denial, nosniff, referrer, permissions and cross-origin policies.
- Verifies the session cookie is Secure, HttpOnly and SameSite=Strict.
- Verifies sensitive session pages use no-store caching.
- Verifies HTTP-to-HTTPS redirect behavior.
- Verifies `/up` and `/ready` remain available without SSL redirect loops.
- Separates `FORCE_SSL` from `ASSUME_SSL` while preserving backward-compatible defaults.
- HTTP evidence artifacts intentionally exclude raw cookie/session values.

## Deployment note

`ASSUME_SSL=true` is appropriate behind a trusted TLS-terminating proxy. Set `ASSUME_SSL=false` when Rails must distinguish direct HTTP from HTTPS and enforce redirects itself.
