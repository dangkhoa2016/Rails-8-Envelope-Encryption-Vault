# FIX46 Release Notes — Production Session Lifecycle Evidence

## Scope

FIX46 turns server-side session lifecycle behavior into production-mode release evidence.

## Changes

- Adds `script/production-session-lifecycle-preflight`.
- Uses a synthetic production user and cleans it up automatically.
- Proves login creates an active server-side session with bounded cookie expiry.
- Proves the signed session cookie is HttpOnly and SameSite=Strict.
- Proves successful reauthentication rotates the server-side session and revokes the previous record.
- Proves a cookie captured before rotation is rejected.
- Proves revoking another session leaves the current session active.
- Proves revoking the current session signs the browser out.
- Proves idle-expired sessions are rejected and revoked server-side.
- Proves absolute-expired sessions are rejected and revoked server-side.
- Requires secret-free evidence and canary non-leakage.
- Integrates session lifecycle evidence into release metadata, checklist, sealing, and off-host evidence.

## Evidence boundary

Timeout cases advance server-side record timestamps directly so the preflight can verify the same production code paths without waiting for the configured 20-minute/12-hour wall-clock periods.

Manual accessibility remains pending.
