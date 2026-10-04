# Production Session Lifecycle — FIX46

## Objective

Prove that production authentication sessions remain bounded, rotatable, revocable, and reject stale/expired identifiers at runtime.

## Runtime evidence

`script/production-session-lifecycle-preflight` boots an isolated production server and creates a temporary synthetic user.

It proves:

- login creates an active server-side Session record,
- the signed `session_id` cookie is HttpOnly, SameSite=Strict, and has an expiry,
- reauthentication revokes the old Session and creates a new active Session,
- a cookie captured before that rotation is rejected,
- another Session can be revoked without ending the current Session,
- revoking the current Session signs the browser out,
- an idle-expired Session is rejected and marked revoked,
- an absolute-expired Session is rejected and marked revoked,
- credential canaries do not appear in captured production logs.

The synthetic user is removed when the preflight exits.

## Timeout methodology

The production defaults remain unchanged. To avoid waiting for real timeout durations, the preflight updates only the synthetic Session record timestamps so that the normal production authentication concern evaluates the record as expired.

## Evidence

Canonical files:

- `SESSION-LIFECYCLE-PREFLIGHT.json`
- `SESSION-LIFECYCLE-PREFLIGHT.log`

All prior release gates remain mandatory.
