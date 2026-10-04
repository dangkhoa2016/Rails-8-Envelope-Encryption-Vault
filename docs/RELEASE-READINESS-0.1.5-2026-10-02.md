# Ruby Envelope Vault 0.1.5 Release Readiness — 2026-10-02

Status: **READY_TO_SEAL**
Development tree: `/content/DEV-0.1.5`
Current version marker: `0.1.5-dev`
Stable base: sealed `RELEASE-0.1.4`

This document records the final pre-seal review. It does not itself promote or rename the development tree.

## Release scope

0.1.5 is a portability, recovery, and product-UX hardening release.

Confirmed unchanged from 0.1.4:

- `db/` schema and migrations;
- `Gemfile`;
- `Gemfile.lock`;
- `config/routes.rb`;
- `app/services/key_providers/`;
- `app/services/vault/`;
- `VaultItemVersion` persistence behavior;
- `MfaSetting` persistence behavior.

The only `VaultItem` model changes are presentation metadata for category guidance. Dashboard controller changes are read-only MFA/session counters.

## Readiness blockers found and resolved

### Stale release documentation

README and CHANGELOG still described stable 0.1.3 / active 0.1.4-dev.

Resolved:
- README now identifies stable 0.1.4 and active 0.1.5-dev;
- CHANGELOG has a 0.1.5-dev entry;
- historical 0.1.4 documents remain historical and were not rewritten.

### Colab-specific recovery dependency

`script/build-current-migration-bundle` still contained a hard-coded fallback to the specific 0.1.4 private DR bundle path under `/content`.

Resolved:
- explicit `REV_SECRETS_ROOT` remains supported;
- Kaggle persistent secrets discovery remains supported;
- sibling secrets discovery remains supported;
- the version-specific private Colab DR fallback was removed;
- recovery contracts reject `PRIVATE-DR-BUNDLE` and hard-coded `0.1.4` in this builder.

### Missing outer artifact checksum sidecar

The first release-candidate restore reported `BUNDLE_SIDECAR_VERIFY=SKIP`.

Resolved:
- migration-bundle builder now emits `.sha256`;
- builder verifies the sidecar before success;
- sidecar is mode 0600;
- recovery contract covers sidecar emission and verification;
- final isolated restore reports `BUNDLE_SIDECAR_VERIFY=PASS`.

## Upgrade compatibility from 0.1.4

The 0.1.4 off-host restored database was opened with the 0.1.5-dev application code.

A historical LocalFile-backed item was selected according to its persisted provider metadata and revealed without printing plaintext.

Markers:

`UPGRADE_014_DATABASE_READ=PASS`

`UPGRADE_014_TO_015_VAULT_REVEAL=PASS`

The database contained both LocalFile and AWS KMS historical versions; the canary respected the stored provider boundary rather than assuming all items used one provider.

## Final verification

Final `script/release-verify` after all readiness fixes:

- repository policy: PASS;
- portability policy: PASS;
- documentation links: `DOC_LINK_CHECK=PASS checked=32`;
- Zeitwerk eager load: PASS;
- Rails: 126 runs / 1077 assertions / 0 failures / 0 errors / 0 skips;
- system: 20 runs / 183 assertions / 0 failures / 0 errors / 0 skips;
- RuboCop: 158 files / 0 offenses;
- Brakeman: 0 security warnings;
- bundler-audit: no vulnerabilities;
- crypto: 36 runs / 70 assertions / 0 failures;
- security: 5 runs / 12 assertions / 0 failures;
- accessibility: 47 runs / 811 assertions / 0 failures / 0 errors / 0 skips.

Final marker:

`RELEASE_VERIFY=PASS version=0.1.5-dev`

Focused recovery contracts:

`39 runs / 760 assertions / 0 failures / 0 errors`

## Final migration release candidate

Archive:

`/content/rev015-release-candidate-artifacts/ruby-envelope-vault-v0.1.5-dev-MIGRATION-BUNDLE.tar.gz`

Sidecar:

`/content/rev015-release-candidate-artifacts/ruby-envelope-vault-v0.1.5-dev-MIGRATION-BUNDLE.tar.gz.sha256`

Archive SHA256:

`d94b4b6dccaf82ac2ed887551b42b84e4b19d275f3c57ece25245b470ac241c1`

Permissions:
- archive: 0600;
- sidecar: 0600.

Artifact gates:

- `BUNDLE_SIDECAR_VERIFY=PASS`;
- `BUNDLE_INTERNAL_VERIFY=PASS`;
- `BUNDLE_PORTABILITY_VERIFY=PASS`;
- `FINAL_CANDIDATE_LEAK_SCAN=PASS`.

Leak scan rejected archive paths matching AWS session/cache state, generic credentials paths, source-local `.bundle/config`, and runtime `tmp/log/storage` paths.

## Final isolated new-host acceptance

The final candidate was restored into separate install, secrets and runtime roots on Google Colab / Ubuntu 24.04.

Port collisions were intentionally present and handled:

- PostgreSQL 5432 -> 5433;
- Redis 6379 -> 6380.

Final markers:

- `BUNDLE_SIDECAR_VERIFY=PASS`;
- `BUNDLE_INTERNAL_VERIFY=PASS`;
- `SOURCE_RESTORE=PASS release=dev`;
- `SECRET_RESTORE=PASS`;
- `EXECUTABLE_REPAIR=PASS`;
- `PROJECT_DOCTOR=PASS`;
- `RAILS_START_MODE=tmux`;
- `HEALTH=200`;
- `RAILS_PROCESS_VERIFY=PASS mode=tmux`;
- `NEW_HOST_SUMMARY=PASS`;
- `NEW_HOST_ACCEPTANCE=PASS version=0.1.5-dev`.

Acceptance services were stopped after the test:

`RELEASE_CANDIDATE_ACCEPTANCE_SERVICES_STOPPED=PASS`

## Readiness conclusion

No known release-readiness blocker remains in the tested scope.

`0.1.5-dev` is ready for the explicit seal step that creates an immutable `RELEASE-0.1.5` candidate/source tree. Stable `RELEASE-0.1.4` remains unchanged.
