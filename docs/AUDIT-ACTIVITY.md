# Audit Activity Center — security and review boundaries

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](AUDIT-ACTIVITY.vi.md)

## What is included

The Security Activity Center is included in the **v1.0.0 community source release** for reviewing account-linked security events. Automated validation covers its service, presenter and browser behavior; production-host acceptance and manual mobile/accessibility review remain separate.

- Four accurate cards summarize account events, sensitive actions, failed checks, and the newest event for the **selected time range**.
- Time range: past 7, 30 (default), or 90 days, or all retained time; filters by category, raw action and outcome (Completed / Failed / Recorded) compose with pagination.
- Events group by application-local date and show time, action title, category and outcome.
- Expanded details expose only presenter-allowlisted context and **truncated** item/request references; they do not reveal secret plaintext.
- Responsive HTML works with GET forms and native details even without JavaScript. The Category→Action selector is enhanced with Stimulus.

## Session request evidence and Vault navigation

New authentication-related Audit events capture a **minimal request snapshot**: Rails-resolved remote IP address, the bounded User-Agent header, HTTP method, and a known authentication route without query parameters. Browser and OS labels are derived for display from User-Agent. Session sign-in, sign-out, reauthentication and failed MFA are supported; unattributed failed login events stay outside the personal account view. Older audit events are **not backfilled**, so missing request context for historical events does not mean those events lacked network traffic.

This is not an HTTP access-log recorder: cookies, authentication headers, X-Forwarded-For raw values, request/response bodies, params and query strings are never copied into Audit metadata. The browser-supplied User-Agent is untrusted, bounded and rendered as text; the IP displayed is Rails `remote_ip` under configured trusted-proxy policy, not proof of device identity. IP/User-Agent are personal data: restrict access, apply the deployment's retention/access policy and avoid including them in public bug reports.

For Vault actions, **Open vault item** appears only when the referenced item currently exists under the authenticated user's `vault_items` relation. Archived items remain navigable; removed, missing, null or other-user references have **no link**. Audit references are never an authorization mechanism. Historical event labels do not reveal decrypted item titles or secret values.

## Correctness of security metrics

**This is an account audit, not a global SIEM.** All listings, category counts and summary cards come from the authenticated user's `audit_events` relation. In the existing application, unsuccessful sign-ins without an authenticated user are recorded globally with no `user_id`, and key-rotation events are system-wide. They are **not** shown or counted in account history. In particular, “0 failed checks” does not establish the absence of anonymous failed sign-ins.

Outcomes are derived conservatively from allowlisted known action identifiers. Explicit `*_failed` actions are `Failed`; known completed operations are `Completed`; future unknown actions and rotation-start are `Recorded`. The UI does **not** turn missing data into a success claim. Counts are independent of category/action/outcome filters, but constrained to the selected time range.

**Do not attribute unsuccessful login attempts to a named account solely from the unauthenticated email parameter.** System/security operator auditing needs a separately authorized design; cross-user events should never be exposed through the regular user view.

## Privacy and threat boundaries

Audit metadata is validated against forbidden sensitive keys by the model, then **allowlisted again** in `AuditEventPresenter`. Displaying arbitrary metadata, decrypted item titles, complete key material, session tokens, full IP addresses or authentication credentials is prohibited. Request IDs and item references are short and strictly for correlation. Never interpret a correlation reference as proof of event attribution or a secret identifier.

The backing AuditEvent model is read-only after persistence through normal Active Record writes, **not** a cryptographically tamper-evident log. No hash chaining, signed export, immutable offsite sink, global admin dashboard or retention guarantee is provided by this UI. These require separate security engineering and operator acceptance.

## Verification

Automated coverage includes range validation, cross-user isolation, unattributed/system-event exclusion, outcome classification, category/action preservation, pagination, browser filters, empty states and safe presenter metadata. Run Rails and Selenium suites and perform keyboard/Android manual acceptance before declaring the feature released. See [qualification](qualification.md), [threat model](THREAT-MODEL.md), [accessibility](ACCESSIBILITY.md) and [production checklist](PRODUCTION-CHECKLIST.md).
