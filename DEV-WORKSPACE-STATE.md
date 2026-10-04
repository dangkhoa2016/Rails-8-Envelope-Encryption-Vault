# Ruby Envelope Vault DEV Workspace State

## Current development authority — 0.1.8-dev

- Active development workspace: `/content/DEV-0.1.8`
- Base sealed release: `/content/RELEASE-0.1.7`
- Base release version: `0.1.7`
- Development version: `0.1.8-dev`
- Production symlink: `/content/current -> /content/RELEASE-0.1.7`
- Production key provider: `aws_kms`
- Production health at DEV-0.1.8 creation: HTTP 200
- Production readiness at DEV-0.1.8 creation: HTTP 200
- Production operator status at DEV-0.1.8 creation: PASS
- Production sealed-source integrity before DEV copy: PASS / 405 files

## 0.1.7 release closure inherited as authority

- release verify: PASS
- isolated restore: PASS
- new-host recovery: PASS
- private DR restore acceptance: PASS
- private DR historical decrypt: PASS
- private DR `/up=200` and `/ready=200`
- private DR restored counts: users=1 / vault_items=1 / vault_item_versions=1 / key_registries=2 / audit_events=92
- outer encrypted private DR off-host round-trip: PASS
- AWS KMS fresh-host rehearsal: PASS
- AWS KMS historical decrypt: PASS
- AWS KMS rewrap: PASS
- sealed-source integrity: PASS / 405 files
- production promotion: PASS

Promoted metadata authority:
`/content/rev017-final-release-artifacts/RELEASE-METADATA.json`

Authoritative 0.1.7 private DR:
`/content/RUBY-ENVELOPE-VAULT-v0.1.7-PRIVATE-DR-SEALED-PRODUCTION-20261004T043922Z.tar.gz.age`

Outer archive SHA-256:
`85c39e97c258b5252e3c5d6ebefedf613bb28a528d3a3c428d5c379b0b7edf9c`

## DEV-0.1.8 creation

`DEV-0.1.8` was copied from the sealed `RELEASE-0.1.7` tree with runtime/generated material excluded:

- `.git`
- `.bundle`
- `.env` / `.env.*`
- `tmp`
- `log`
- `storage`
- `vendor/bundle`
- compiled assets

`VERSION` was changed only in the new development tree to:

`0.1.8-dev`

Production remained pinned to `RELEASE-0.1.7` throughout workspace creation.

## Development rules

- Do not modify `/content/RELEASE-0.1.7`.
- Do not repoint `/content/current` during normal development.
- Do not rotate AWS KMS keys unless explicitly requested.
- Never print AWS credentials, KMS key IDs, or decrypted Vault plaintext into logs/evidence.
- Every behavioral change must have regression coverage.
- Before a future 0.1.8 RC, re-run production private-DR restore and historical decrypt acceptance.

## Baseline — PASS

Authority:
`docs/DEV-0.1.8-BASELINE-2026-10-04.md`

Clean baseline verification passed after hardening the shared system-test
sign-in synchronization contract.

Baseline gates:

- Rails: 168 runs / 1566 assertions / 0 failures
- System: 21 runs / 223 assertions / 0 failures
- RuboCop: 167 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- Crypto: 49 runs / 135 assertions / 0 failures
- Security: 5 runs / 12 assertions / 0 failures
- Accessibility: 53 runs / 1070 assertions / 0 failures
- RELEASE_VERIFY=PASS version=0.1.8-dev

## Milestone 1 — production DR provenance gate

Status: PASS.

Added:

- `script/private-dr-provenance-preflight`
- `test/private_dr_provenance_preflight_test.rb`

Release sealing now requires provenance evidence proving the private DR is a
production-authority snapshot tied by SHA-256 to the exact accepted archive.

The gate rejects:

- current runtime/DEV database as production source;
- wrong target release version;
- production counts below required minimums;
- provenance counts that differ from restore acceptance;
- inherited promoted snapshots without migration-set identity proof.

Final Milestone 1 regression:

- Rails: 174 runs / 1613 assertions / 0 failures
- System: 21 runs / 223 assertions / 0 failures
- RuboCop: 168 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- Crypto: 49 runs / 135 assertions / 0 failures
- Security: 5 runs / 12 assertions / 0 failures
- Accessibility: 53 runs / 1092 assertions / 0 failures
- RELEASE_VERIFY=PASS version=0.1.8-dev

Authority:
`docs/DEV-0.1.8-MILESTONE-1-PRIVATE-DR-PROVENANCE-2026-10-04.md`

## Milestone 2 — stable production database contract

Status: PASS.

Added:

- `script/production-database-name`
- `script/production-database-contract`
- `script/prepare-production-database`
- `script/release-prepare-promotion`
- `test/production_database_contract_test.rb`

Production startup now requires stable release database naming by default.
Isolated restore acceptance must opt into `PRODUCTION_DATABASE_CONTRACT_MODE=isolated`
explicitly.

Private DR acceptance supports `--database-name` and only preserves a
`--keep-db` database after the complete acceptance has passed.

The official promotion preparation step restores directly into the deterministic
stable database name, verifies production provenance, and emits non-secret
preparation evidence before repointing is allowed.

Post-promotion evidence rechecks the live database name before promoted metadata
can be written.

Final Milestone 2 regression:

- Rails: 183 runs / 1723 assertions / 0 failures
- System: 21 runs / 223 assertions / 0 failures
- RuboCop: 169 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- Crypto: 49 runs / 135 assertions / 0 failures
- Security: 5 runs / 12 assertions / 0 failures
- Accessibility: 53 runs / 1116 assertions / 0 failures
- RELEASE_VERIFY=PASS version=0.1.8-dev

Authority:
`docs/DEV-0.1.8-MILESTONE-2-STABLE-PRODUCTION-DATABASE-2026-10-04.md`

No 0.1.8 production database was created during this development milestone.

## Milestone 3 — off-host runtime portability

Status: PASS.

Added:

- `script/rclone-resolve`
- `script/provision-rclone`
- `script/offsite-capability-preflight`
- `test/offsite_runtime_contract_test.rb`

The portable provisioner pins rclone v1.75.0 and verifies the official archive
SHA-256 before installing under the external runtime tree.

Live Colab capability proof:

- rclone v1.75.0 provisioned under `/content/.ruby-envelope-vault-runtime/bin`;
- binary SHA-256: `f3f9aff817f9766029e50adf9a7963c169e475b8f10c7927823568a0d9443db7`;
- independent remote type: `s3`;
- remote read: PASS;
- write/download/SHA/delete probe: PASS;
- updated `offsite-roundtrip` end-to-end probe: PASS.

`release-seal-prepromote` can now require the offsite capability gate before
`release-verify`, so missing runtime tooling or remote write failures abort
before expensive release gates.

Final Milestone 3 regression:

- Rails: 189 runs / 1796 assertions / 0 failures
- System: 21 runs / 223 assertions / 0 failures
- RuboCop: 170 files / 0 offenses
- Brakeman: 0 warnings
- bundler-audit: no vulnerabilities
- Crypto: 49 runs / 135 assertions / 0 failures
- Security: 5 runs / 12 assertions / 0 failures
- Accessibility: 53 runs / 1116 assertions / 0 failures
- RELEASE_VERIFY=PASS version=0.1.8-dev

Authority:
`docs/DEV-0.1.8-MILESTONE-3-OFFSITE-RUNTIME-PORTABILITY-2026-10-04.md`

## Next focus

See `ROADMAP-0.1.8.md`.

Recommended next milestone: add a full release/promotion dry-run orchestrator
that exercises provenance, stable DB preparation, offsite capability and seal
contracts without repointing production.
