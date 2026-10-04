# FIX41 Production HTTP Security

FIX41 verifies the production HTTP security contract against a real isolated Rails production server.

## Preflight

Run:

```bash
./script/production-http-security-preflight
```

The command emits non-secret evidence:
- `HTTP-SECURITY-PREFLIGHT.json`
- `HTTP-SECURITY-PREFLIGHT.log`

Raw response headers and session-cookie values exist only in a temporary directory and are deleted when the preflight exits.
## Verified response contract

The production session page must prove:
- HTTP 200 over a request marked HTTPS by the trusted proxy header;
- Content-Security-Policy with restrictive defaults and request nonce;
- Strict-Transport-Security with a positive max-age and subdomains;
- X-Frame-Options DENY;
- X-Content-Type-Options nosniff;
- Referrer-Policy same-origin, preserving same-origin request provenance needed by Rails origin-based CSRF checks while suppressing referrer data on cross-origin navigation;
- restrictive Permissions-Policy;
- same-origin COOP and CORP;
- no-store caching;
- session cookie flags Secure, HttpOnly and SameSite=Strict.

With `FORCE_SSL=true` and `ASSUME_SSL=false`, direct HTTP must redirect to HTTPS.
## TLS topology

`FORCE_SSL` controls Rails SSL enforcement.

`ASSUME_SSL` tells Rails whether an upstream trusted proxy already terminated TLS.

The default remains backward compatible: when `ASSUME_SSL` is not set, it follows `FORCE_SSL`.

For a trusted TLS-terminating reverse proxy, use `ASSUME_SSL=true`.
For direct Rails HTTP/HTTPS distinction, use `ASSUME_SSL=false`.

The release preflight intentionally uses `FORCE_SSL=true ASSUME_SSL=false` so redirect behavior is actually exercised.

## Health endpoints

`/up` and `/ready` are intentionally excluded from SSL redirect and host authorization to avoid load-balancer/readiness redirect loops. The preflight requires both endpoints to return HTTP 200 without a Location header.
