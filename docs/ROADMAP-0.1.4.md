# Ruby Envelope Vault — 0.1.4 Development Roadmap

## Status

- Development version: `0.1.4-dev`
- Stable baseline: `0.1.3`
- Stable source remains immutable: `/mnt/workspace/ruby-envelope-vault/RELEASE-0.1.3`
- Development source: `/mnt/workspace/ruby-envelope-vault/DEV-0.1.4`
- Promotion status: **NOT PROMOTED**
- Live `current`: must remain on stable `0.1.3` during normal development.

## Milestone intent

0.1.4 is the first post-consolidation development milestone. It must not restart the old FIX-number sequence and must not re-debug stable 0.1.3 domains without concrete regression evidence.

## Regression floor inherited from 0.1.3

Every future 0.1.4 release candidate must preserve the accepted 0.1.3 gates: Rails/system behavior; RuboCop, Brakeman and bundler-audit; crypto/security self-tests; UX/accessibility automation; HTTP security; safe failures/request correlation; logging redaction; CSRF/origin; rate limiting; session lifecycle; upgrade compatibility; recovery/restore; public-package sanitization; sealed source; explicit promotion; and real off-host SHA-256 round trips.

## Workstream A — Manual accessibility evidence

Goal: close the current `PENDING` human-accessibility boundary without making an unsupported WCAG-conformance claim.

1. Create a repeatable manual keyboard-navigation checklist for login, vault list, create/edit, reveal/reauth, MFA, sessions and audit history.
2. Record focus visibility/order, dialog behavior, form error association, zoom/reflow and screen-reader smoke observations.
3. Keep automated accessibility checks as regression tests, not a substitute for human review.
4. Store dated human evidence separately from source-generated claims.
5. Change `ux_accessibility_manual_status` only after actual human evidence exists.

Exit gate: manual evidence recorded and reviewed; automated accessibility remains PASS; no formal WCAG claim unless independently justified.

## Workstream B — Operator and deployment UX

Goal: make recovery/start/stop/diagnostics clearer on notebook and durable Linux hosts without weakening security boundaries.

1. Add one concise operator entrypoint/document distinguishing Kaggle demo recovery from durable-host operation.
2. Report stable/dev identity, current symlink, Rails health, PostgreSQL/Redis state and evidence paths without printing secrets.
3. Keep recovery idempotent and preserve persistent database/runtime reuse.
4. Add restart/self-heal regression coverage where practical.
5. Preserve explicit operator promotion.

## Workstream C — KEK provider evolution

Goal: strengthen the provider boundary so a future KMS/HSM-backed KEK can be introduced without changing encrypted vault-record schema.

1. Audit `KeyProviders::Base`, `LocalFile`, registry and key-rotation contracts.
2. Define provider capability/error semantics and configuration validation.
3. Add a non-production contract-test provider if useful.
4. Design, but do not silently enable, an external-KMS adapter boundary.
5. Preserve LocalFile compatibility and current ciphertext/wrapped-DEK records.
6. Require explicit migration/recovery evidence before any provider becomes production-supported.

Initial non-goals: no forced cloud-vendor dependency, no automatic KEK upload, and no encrypted-record schema migration merely for provider refactoring.

## Workstream C current status

Completed in the current development checkpoint:

- provider base contract includes verify_key!;
- key rotation resolves providers through Registry.fetch;
- non-LocalFile in-memory provider contract and rotation evidence PASS;
- vendor-neutral ExternalKms skeleton added;
- generic configuration/unavailable error model added;
- fake KMS contract and rotation evidence PASS;
- production Registry was initially kept closed during provider-neutral development; stable 0.1.4 later accepted explicit `aws_kms` support after live KMS evidence;
- external KMS recovery/custody requirements documented.

Historical development note: the list below described the remaining gates before AWS KMS was selected and accepted later in 0.1.4. Stable 0.1.4 subsequently selected AWS KMS, implemented the vendor adapter, and accepted live two-key rotation plus historical decrypt evidence.

Future hardening still worth pursuing:

- credential-expiry and provider-outage drills;
- fresh-host cloud-specific recovery exercises;
- explicit failed-rotation rollback rehearsal;
- expanded operator diagnostics and redaction review.

## Workstream D — Release engineering for 0.1.4

1. Keep development-baseline evidence outside stable source.
2. Keep `current -> RELEASE-0.1.3` throughout development.
3. Run the full inherited regression floor before RC creation.
4. Fork immutable `RELEASE-0.1.4-RC1` only after scope completion.
5. Seal before promotion and stop at `PROMOTION_REQUIRED=yes`.
6. Exercise rollback before stable 0.1.4 promotion.
7. Round-trip canonical artifacts and evidence off-host.

## Explicitly out of scope unless a regression appears

Do not re-open FIX45 rate limiting, FIX46 session lifecycle, stable HTTP security, safe errors/request correlation, logging redaction, CSRF/origin, new-host recovery, isolated restore, public package sanitization, stable sealed-source evidence, FIX46-to-0.1.3 compatibility, or the 0.1.3 rollback rehearsal solely because 0.1.4 started.

## Development discipline

- Never edit `RELEASE-0.1.3`.
- Never repoint `current` to `DEV-0.1.4` as a convenience.
- Run development servers on a separate port/window when needed.
- New evidence must identify `0.1.4-dev`; do not overwrite stable 0.1.3 canonical evidence.
- Do not emit release-acceptance markers for `0.1.4-dev`.

## Recommended implementation order

1. Establish and verify the clean 0.1.4-dev baseline.
2. Implement Workstream B operator/deployment UX first.
3. Add Workstream A manual-accessibility evidence framework.
4. Audit and test Workstream C provider contracts before implementing any external provider.
5. Re-run the full regression floor.
6. Decide whether completed scope is sufficient for `0.1.4-RC1`.
