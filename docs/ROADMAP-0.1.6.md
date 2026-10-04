# Ruby Envelope Vault — 0.1.6 Development Roadmap

## Status

- Development version: `0.1.6-dev`
- Sealed stable baseline: `RELEASE-0.1.5`
- Active development workspace: `/content/DEV-0.1.6`
- Live `current`: `/content/RELEASE-0.1.5`
- Promotion status: **development only; not promoted**

## Development rule

0.1.6 inherits the complete accepted 0.1.5 regression floor. Stable release source must remain immutable, and development servers/tests must not replace the live `current` release.

## Milestone 1 — Release truth and provenance consolidation

Goal: make repository documentation agree with the actually promoted 0.1.5 release before adding new product scope.

1. Replace stale 0.1.3/current-release wording.
2. Convert 0.1.5 candidate notes into stable-release notes.
3. Record the clean 0.1.6 baseline and its sealed 0.1.5 provenance.
4. Keep promoted/off-host/sealed-source status factual and evidence-backed.
5. Keep manual accessibility explicitly pending rather than inferring a human PASS.

Exit gate:
- documentation links PASS;
- README/release notes/changelog identify 0.1.5 as stable;
- 0.1.6 baseline evidence is recorded;
- no byte in `RELEASE-0.1.5` changes.

## Milestone 2 — Manual accessibility evidence closure

Goal: close the only intentionally human-only release evidence boundary.

- use the existing manual accessibility worksheet and FIX40 acceptance protocol;
- record keyboard workflow, focus order/visibility, reflow/zoom, screen-reader smoke, contrast/touch observations;
- retain automated accessibility as regression evidence only;
- do not set manual status to PASS until a person actually completes and records the review;
- do not make a WCAG conformance claim without separate justification.

## Milestone 3 — AWS KMS authority reconciliation and hardening audit

Stable 0.1.4 authority and current code already establish explicit `aws_kms` Registry support. The first task is therefore to reconcile stale development documentation, not to re-activate the provider.

Audit goals:
- confirm Registry/AWS client/rotation regression coverage remains green;
- align historical implementation docs with stable 0.1.4 release authority;
- keep additional fresh-host cloud recovery, outage/credential-expiry, failed-rotation rollback and operator diagnostics as future hardening;
- do not weaken fail-closed provider configuration or LocalFile compatibility.

## Milestone 4 — KMS failure-mode and rollback hardening

Status: COMPLETE.

- Key rotation mutations are now wrapped in a new database transaction under the existing advisory lock.
- Mid-rotation provider outage rolls back earlier record updates instead of leaving partial rewrap state.
- Destination KeyRegistry activation and completion audit are rolled back on failure.
- Secret-safe started/failed audit evidence remains available to operators.
- Focused regression: 22 runs / 81 assertions / 0 failures.
- Full release verify: PASS.

## Milestone 5 — KMS operator diagnostics and credential/outage hardening

Status: COMPLETE.

- Added secret-safe key-provider diagnostics with allowlisted provider/status/category/remote fields.
- Added `script/key-provider-status` and integrated readiness into `script/operator-status`.
- Non-ready provider now fails the combined operator gate.
- Credential-expiry, access-denied, wrap and unwrap failures are normalized without leaking SDK/provider details.
- Focused diagnostics/security contracts: 53 runs / 888 assertions / 0 failures.
- Full release verify: PASS.

## Milestone 6 — AWS KMS fresh-host recovery rehearsal

Status: COMPLETE / LIVE AWS PASS.

- Added `script/aws-kms-fresh-host-rehearsal`.
- Synthetic ExternalKms wrap, rewrap and historical decrypt rehearsal: PASS.
- Machine-readable evidence records whether live AWS was actually available.
- Evidence records neither credential values nor KMS key IDs.
- Live AWS execution completed after valid IAM credentials were supplied on the restored Colab host.
- STS identity, KMS readiness, live single-key smoke, two-key rewrap/historical decrypt, Vault rotation and fresh-host live smoke all PASS.
- Live-KMS executable portability was hardened by explicitly loading `bundler/setup` in all three live Ruby scripts.
- Machine-readable evidence records `live_aws_ready=yes`, `live_smoke=pass`, and no credential/key-id values.
- Full release verify after live execution: PASS.
